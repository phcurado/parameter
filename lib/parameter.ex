defmodule Parameter do
  @moduledoc """
  `Parameter` is a library for dealing with complex datatypes by solving the following problems:
  - Schema creation and validation
  - Input data validation
  - Deserialization
  - Serialization

  ## Examples

  Create a schema

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

  Load (deserialize) the schema against external parameters:

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

  or Dump (serialize) a populated schema to params:

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
  alias Parameter.Loader
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
  """
  @spec load(module() | atom(), map() | list(map()), Keyword.t()) ::
          {:ok, any()} | {:error, any()}
  def load(schema, input, opts \\ []) do
    opts = parse_opts(opts)
    Loader.load(schema, input, opts)
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
  @spec dump(module() | atom(), map() | list(map), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def dump(schema, input, opts \\ []) do
    exclude = Keyword.get(opts, :exclude, [])
    many = Keyword.get(opts, :many, false)

    Types.validate!(:list, exclude)
    Types.validate!(:boolean, many)
    Dumper.dump(schema, input, exclude: exclude, many: many)
  end

  @spec validate(module() | atom(), map() | list(map), Keyword.t()) :: :ok | {:error, any()}
  def validate(schema, input, opts \\ []) do
    many = Keyword.get(opts, :many, false)
    Types.validate!(:boolean, many)
    Validator.validate(schema, input, many: many)
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
    Types.validate!(:list, exclude)
    Types.validate!(:boolean, many)

    [struct: struct, unknown: unknown, exclude: exclude, many: many]
  end
end
