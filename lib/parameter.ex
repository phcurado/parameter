defmodule Parameter do
  @moduledoc """
  `Parameter` helps you shape data from external sources into Elixir internal types. Use it to deal with any external data in general, such as API integrations, parsing user input, or validating data that comes into your system.

  `Parameter` offers the following helpers:
  - Schema creation and validation
  - Input data validation
  - Deserialization
  - Serialization

  ## Schema

  First step for dealing with external data is to create a schema that shape the data:

      defmodule UserParam do
        use Parameter.Schema
        alias Parameter.Validators

        param do
          field :first_name, :string, key: "firstName", required: true
          field :last_name, :string, key: "lastName"
          field :email, :string, validator: &Validators.email/1
          has_one :address, AddressParam do
            field :city, :string, required: true
            field :street, :string
            field :number, :integer
          end
        end
      end

  Now it's possible to Load (deserialize) the schema against external data:

      params = %{
        "firstName" => "John",
        "lastName" => "Doe",
        "email" => "john@email.com",
        "address" => %{"city" => "New York", "street" => "York"}
      }
      Parameter.load(UserParam, params)
      {:ok, %{
        first_name: "John",
        last_name: "Doe",
        email: "john@email.com",
        address: %{city: "New York", street: "York"}
      }}

  or Dump (serialize) a populated schema to the source:

      schema = %{
        first_name: "John",
        last_name: "Doe",
        email: "john@email.com",
        address: %{city: "New York", street: "York"}
      }
      Parameter.dump(UserParam, params)
      {:ok, %{
        "firstName" => "John",
        "lastName" => "Doe",
        "email" => "john@email.com",
        "address" => %{"city" => "New York", "street" => "York"}
      }}

  For more schema options checkout `Parameter.Schema`
  """

  alias Parameter.Dumper
  alias Parameter.Field
  alias Parameter.Loader
  alias Parameter.Meta
  alias Parameter.Types
  alias Parameter.Validator

  @unknown_opts [:error, :ignore]

  @doc """
  Loads parameters into the given schema.

  ## Options

    * `:struct` - If set to `true` loads the schema into a structure. If `false` (default)
    loads with plain maps.

    * `:unknown` - Defines the behaviour when unknown fields are presented on the parameters.
    The options are `:ignore` (default) or `:error`.

    * `:exclude` - Accepts a list of fields to be excluded when loading the parameters. This
    option is useful if you have fields in your schema are only for dump. The field will not
    be checked for any validation if it's on the exclude list.

    * `:many` - When `true` will parse the input data as list, when `false` (default) it parses as map


  ## Examples

      defmodule UserParam do
        use Parameter.Schema

        param do
          field :first_name, :string, key: "firstName", required: true
          field :last_name, :string, key: "lastName"
          has_one :address, Address do
            field :city, :string, required: true
            field :street, :string
            field :number, :integer
          end
        end
      end

      params = %{
        "address" => %{"city" => "New York", "street" => "broadway"},
        "firstName" => "John",
        "lastName" => "Doe"
      }
      Parameter.load(UserParam, params)
      {:ok, %{
        first_name: "John",
        last_name: "Doe",
        address: %{city: "New York", street: "broadway"}
      }}

      # Using struct options
      Parameter.load(UserParam, params, struct: true)
      {:ok, %UserParam{
        first_name: "John",
        last_name: "Doe",
        address: %AddressParam{city: "New York", street: "broadway"}
      }}

      # Using many: true for lists
      Parameter.load(UserParam, [params, params], many: true)
      {:ok,
      [
        %{
          address: %{city: "New York", street: "broadway"},
          first_name: "John",
          last_name: "Doe"
        },
        %{
          address: %{city: "New York", street: "broadway"},
          first_name: "John",
          last_name: "Doe"
        }
      ]}

      # Excluding fields
      Parameter.load(UserParam, params, exclude: [:first_name, {:address, [:city]}])
      {:ok, %{
        last_name: "Doe",
        address: %{street: "broadway"}
      }}

      # Unknown fields should return errors
      params = %{"user_token" => "3hgj81312312"}
      Parameter.load(UserParam, params, unknown: :error)
      {:error, %{"user_token" => "unknown field"}}

      # Invalid data should return validation errors:
      params = %{
        "address" => %{"city" => "New York", "number" => "123AB"},
        "lastName" => "Doe"
      }
      Parameter.load(UserParam, params)
      {:error, %{
        first_name: "is required",
        address: %{number: "invalid integer type"},
      }}

      Parameter.load(UserParam, [params, params], many: true)
      {:error,
      %{
        0 => %{address: %{number: "invalid integer type"}, first_name: "is required"},
        1 => %{address: %{number: "invalid integer type"}, first_name: "is required"}
      }}

  ### Loading map with atom keys
  It's also possible to load map with atom keys. Parameter schemas should not implement the `key`
  option for this to work.

      defmodule UserParam do
        use Parameter.Schema

        param do
          field :first_name, :string, required: true
          field :last_name, :string
        end
      end

      params = %{
        first_name: "John",
        last_name: "Doe"
      }
      Parameter.load(UserParam, params)
      {:ok, %{
        first_name: "John",
        last_name: "Doe"
      }}

      # String maps will also be correctly loaded if they have the same key
      params = %{
        "first_name" => "John",
        "last_name" => "Doe"
      }
      Parameter.load(UserParam, params)
      {:ok, %{
        first_name: "John",
        last_name: "Doe"
      }}

      # But the same key should not be present in both String and Atom keys:
      params = %{
        "first_name" => "John",
        first_name: "John"
      }
      Parameter.load(UserParam, params)
      {:error, %{
        first_name: "field is present as atom and string keys"
      }}

  """
  @spec load(module() | list(Field.t()), map() | list(map()), Keyword.t()) ::
          {:ok, any()} | {:error, any()}
  def load(schema, input, opts \\ []) do
    opts = parse_opts(opts)

    meta = Meta.new(schema, input, operation: :load)
    Loader.load(meta, opts)
  end

  @doc """
  Dump the loaded parameters.

  ## Options

    * `:exclude` - Accepts a list of fields to be excluded when dumping the loaded parameter. This
    option is useful if you have fields in your schema are only for loading.

    * `:many` - When `true` will parse the input data as list, when `false` (default) it parses as map


  ## Examples

      defmodule UserParam do
        use Parameter.Schema

        param do
          field :first_name, :string, key: "firstName", required: true
          field :last_name, :string, key: "lastName"
          has_one :address, Address do
            field :city, :string, required: true
            field :street, :string
            field :number, :integer
          end
        end
      end

      loaded_params = %{
        first_name: "John",
        last_name: "Doe",
        address: %{city: "New York", street: "broadway"}
      }

      Parameter.dump(UserParam, params)
      {:ok, %{
        "address" => %{"city" => "New York", "street" => "broadway"},
        "firstName" => "John",
        "lastName" => "Doe"
      }}

      # excluding fields
      Parameter.dump(UserParam, params, exclude: [:first_name, {:address, [:city]}])
      {:ok, %{
        "address" => %{"street" => "broadway"},
        "lastName" => "Doe"
      }}
  """
  @spec dump(module() | list(Field.t()), map() | list(map), Keyword.t()) ::
          {:ok, any()} | {:error, any()}
  def dump(schema, input, opts \\ []) do
    exclude = Keyword.get(opts, :exclude, [])
    many = Keyword.get(opts, :many, false)

    Types.validate!(:array, exclude)
    Types.validate!(:boolean, many)

    meta = Meta.new(schema, input, operation: :dump)
    Dumper.dump(meta, exclude: exclude, many: many)
  end

  @doc """
  Validate parameters. This function is meant to be used when the data is loaded or
  created internally. `validate/3` will validate field types, required fields and
  `Parameter.Validators` functions.

  ## Options

    * `:exclude` - Accepts a list of fields to be excluded when validating the parameters.

    * `:many` - When `true` will parse the input data as list, when `false` (default) it parses as map


  ## Examples

      defmodule UserParam do
        use Parameter.Schema

        param do
          field :first_name, :string, key: "firstName", required: true
          field :last_name, :string, key: "lastName"
          has_one :address, Address do
            field :city, :string, required: true
            field :street, :string
            field :number, :integer
          end
        end
      end

      params = %{
        first_name: "John",
        last_name: "Doe",
        address: %{city: "New York", street: "broadway"}
      }

      Parameter.validate(UserParam, params)
      :ok

      # Invalid data
      params = %{
        last_name: 12,
        address: %{city: "New York", street: "broadway", number: "A"}
      }

      Parameter.validate(UserParam, params)
      {:error,
        %{
          address: %{number: "invalid integer type"},
          first_name: "is required",
          last_name: "invalid string type"
        }
      }
  """
  @spec validate(module() | list(Field.t()), map() | list(map), Keyword.t()) ::
          :ok | {:error, any()}
  def validate(schema, input, opts \\ []) do
    exclude = Keyword.get(opts, :exclude, [])
    many = Keyword.get(opts, :many, false)

    Types.validate!(:array, exclude)
    Types.validate!(:boolean, many)

    meta = Meta.new(schema, input, operation: :validate)
    Validator.validate(meta, exclude: exclude, many: many)
  end

  defp parse_opts(opts) do
    unknown = Keyword.get(opts, :unknown, :ignore)

    if unknown not in @unknown_opts do
      raise("unknown field options should be #{inspect(@unknown_opts)}")
    end

    struct = Keyword.get(opts, :struct, false)
    exclude = Keyword.get(opts, :exclude, [])
    many = Keyword.get(opts, :many, false)

    Types.validate!(:boolean, struct)
    Types.validate!(:array, exclude)
    Types.validate!(:boolean, many)

    [struct: struct, unknown: unknown, exclude: exclude, many: many]
  end
end
