defmodule Parameter do
  @moduledoc """
  `Parameter` is a library for dealing with complex datatypes by solving the following problems:
  - Schema creation and validation
  - Input data validation
  - Deserialization
  - Serialization

  ## Example

  Create a schema

      defmodule UserParam do
        use Parameter.Schema
        alias Parameter.Validators

        param do
          field :first_name, :string, key: "firstName", required: true
          field :last_name, :string, key: "lastName"
          field :email, :string, validator: &Validators.email(&1)
          has_one :address, Address do
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
      Parameter.load(User, params)
      {:ok, %{
        first_name: "John",
        last_name: "Doe",
        email: "john@email.com",
        main_address: %{city: "New York", street: "York"}
      }}

  or Dump (serialize) a populated schema to params:

      schema = %{
          first_name: "John",
          last_name: "Doe",
          email: "john@email.com",
          main_address: %{city: "New York", street: "York"}
        }
      Parameter.dump(User, params)
      {:ok,
      %{
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

  @unknown_opts [:error, :ignore]

  @spec load(module() | atom(), map(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def load(schema, input, opts \\ []) do
    opts = parse_opts(opts)
    Loader.load(schema, input, opts)
  end

  @spec dump(module() | atom(), map(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def dump(schema, input, opts \\ []) when is_map(input) do
    exclude = Keyword.get(opts, :exclude, [])
    Types.validate!(:list, exclude)
    Dumper.dump(schema, input, exclude: exclude)
  end

  defp parse_opts(opts) do
    unknown = Keyword.get(opts, :unknown, :ignore)

    if unknown not in @unknown_opts do
      raise("unknown field options should be #{inspect(@unknown_opts)}")
    end

    struct = Keyword.get(opts, :struct, false)

    Types.validate!(:boolean, struct)

    exclude = Keyword.get(opts, :exclude, [])

    Types.validate!(:list, exclude)

    [struct: struct, unknown: unknown, exclude: exclude]
  end
end
