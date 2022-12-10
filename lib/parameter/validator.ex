defmodule Parameter.Validator do
  @moduledoc false

  alias Parameter.Field
  alias Parameter.Schema
  alias Parameter.SchemaFields
  alias Parameter.Types

  @type opts :: [exclude: list(), many: boolean()]

  @spec validate(module() | atom() | list(Field.t()), map() | list(map()), opts) ::
          :ok | {:error, any()}
  def validate(schema, input, opts) do
    if schema in Types.base_types() do
      validate_type(schema, input, opts)
    else
      validate_schema(schema, input, opts)
    end
  end

  defp validate_schema(schema, input, opts) when is_map(input) do
    schema_keys = Schema.field_keys(schema)

    Enum.reduce(schema_keys, %{}, fn schema_key, errors ->
      field = Schema.field_key(schema, schema_key)

      case SchemaFields.process_map_value(field, input, opts, :validate) do
        {:error, error} ->
          Map.put(errors, field.name, error)

        {:ok, :ignore} ->
          errors

        :ok ->
          errors
      end
    end)
    |> parse_result()
  end

  defp validate_schema(schema, input, opts) when is_list(input) do
    if Keyword.get(opts, :many) do
      SchemaFields.list_field_handler(schema, input, opts, :validate)
    else
      {:error,
       "received a list with `many: false`, if a list is expected pass `many: true` on options"}
    end
  end

  defp validate_type(type, input, opts) do
    SchemaFields.field_handler(type, input, opts, :validate)
  end

  defp parse_result(errors) do
    if errors == %{} do
      :ok
    else
      {:error, errors}
    end
  end
end
