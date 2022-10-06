defmodule Parameter do
  @moduledoc """
  `Parameter` is a library for dealing with complex datatypes by solving the following problems:
  - Schema creation and validation
  - Input data validation
  - Deserialization
  - Serialization

  ## Schema

  First step for building the schema of your data is creating the schema definition.
  This can be achived by using the `Parameter.Schema` macro.
      defmodule UserSchema do
        use Parameter.Schema

        param do
          param :first_name, :string, key: "firstName", required: true
          param :last_name, :string, key: "lastName", required: true, default: ""
          param :age, :integer
          param :address, {:map, AddressSchema}, required: true
        end
      end

  And the `AddressSchema`:

      defmodule AddressSchema do
        use Parameter.Schema

        param do
          param :city, :string, required: true
          param :street, :string
          param :number, :integer
        end
      end

  Each field needs to define the type that will be parsed and the options (if any). The types available are:

  - `:string`
  - `:atom`
  - `:integer`
  - `:float`
  - `:boolean`
  - `{:map, inner_type}`
  - `{:array, inner_type}`
  - `:map`
  - `:array`
  - `:date`
  - `:time`
  - `:datetime`
  - `:naive_datetime`
  - `module`*

  \\* Any module that implements the `Parameter.Field` behaviour is elegible to be a field in the schema definition.

  The options available for the field definition are:
  - `key`: This is the key on the external source that will be converted to the param definition.
  As an example, if you receive data from an external source that uses snake case for mapping `first_name`, this flag should be `key: "firstName"`.
  If this parameter is not set it will default to the field name.
  - `default`: default value of the field.
  - `required`: defines if the field needs to be present when parsing the input.

  After the definition the schema can be validate and parsed against external parameters using the `Parameter.load/3` function.


  ## Data Deserialization

  This is a common requirement when you receive data from an external source and wants to
  validate and deserialize this data to an Elixir definition. This can be achived using `Parameter.load/2` or `Parameter.load/3` functions:

      iex> params = %{
            "address" => %{"city" => "Tallinn"},
            "age" => "32",
            "firstName" => "Paulo",
            "lastName" => "Curado"
          }
      ...> Parameter.load(UserSchema, params)
      {:ok,
        %{
          address: %{city: "Tallinn"},
          age: 32,
          first_name: "Paulo",
          last_name: "Curado"
        }
      }

  Adding invalid data should return validation errors:

      iex> params = %{
            "address" => %{"city" => "Tallinn", "number" => "123AB"},
            "age" => "AA",
            "firstName" => "Paulo",
            "lastName" => "Curado"
          }
      ...> Parameter.load(UserSchema, params)
      {:error, %{address: %{number: "invalid integer type"}, age: "invalid integer type"}}
  """

  alias Parameter.Field

  @load_opts [:unknown_field]
  @unknown_field_opts [:error, :exclude]

  def load(module_schema, input, opts \\ []) when is_map(input) do
    if opts !== [] and opts not in @load_opts,
      do: raise("load options should be #{inspect(@load_opts)}")

    unknown_field = Keyword.get(opts, :unknown_field, :exclude)

    if unknown_field not in @unknown_field_opts,
      do: raise("unknown field options should be #{inspect(@unknown_field_opts)}")

    schema_keys = module_schema.__param__(:fields, :keys)

    Enum.reduce(input, {%{}, [], %{}}, fn {key, value}, {result, unknown_fields, errors} ->
      if key not in schema_keys do
        {result, [key | unknown_fields], errors}
      else
        field = module_schema.__param__(:field, key)

        case load_type_value(field, value, opts) |> parse_loaded_input() do
          {:error, error} ->
            errors = Map.put(errors, field.name, error)
            {result, unknown_fields, errors}

          {:ok, loaded_value} ->
            result = Map.put(result, field.name, loaded_value)
            {result, unknown_fields, errors}

          loaded_value ->
            result = Map.put(result, field.name, loaded_value)
            {result, unknown_fields, errors}
        end
      end
    end)
    |> parse_loaded_input()
  end

  defp load_type_value(%Field{type: {_type, inner_module}}, value, opts) do
    load(inner_module, value, opts)
  end

  defp load_type_value(field, value, _opts) do
    Field.load(field, value)
  end

  defp parse_loaded_input({result, _unknown_fields, errors}) do
    if errors == %{} do
      {:ok, result}
    else
      {:error, errors}
    end
  end

  defp parse_loaded_input(result), do: result
end
