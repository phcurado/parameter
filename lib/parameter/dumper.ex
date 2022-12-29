defmodule Parameter.Dumper do
  @moduledoc false

  alias Parameter.Meta
  alias Parameter.Schema
  alias Parameter.SchemaFields

  @type opts :: [exclude: list(), many: boolean()]

  @spec dump(Meta.t(), opts) :: {:ok, any()} | {:error, any()}
  def dump(%Meta{schema: schema, input: input} = meta, opts) when is_map(input) do
    schema_keys = Schema.field_keys(schema)

    Enum.reduce(schema_keys, {%{}, %{}}, fn schema_key, {result, errors} ->
      field = Schema.field_key(schema, schema_key)

      case SchemaFields.process_map_value(meta, field, opts) do
        {:error, error} ->
          errors = Map.put(errors, field.name, error)
          {result, errors}

        {:ok, :ignore} ->
          {result, errors}

        {:ok, loaded_value} ->
          result = Map.put(result, field.key, loaded_value)
          {result, errors}
      end
    end)
    |> parse_loaded_input()
  end

  def dump(%Meta{input: input} = meta, opts) when is_list(input) do
    if Keyword.get(opts, :many) do
      SchemaFields.process_list_value(meta, input, opts)
    else
      {:error,
       "received a list with `many: false`, if a list is expected pass `many: true` on options"}
    end
  end

  defp parse_loaded_input({result, errors}) do
    if errors == %{} do
      {:ok, result}
    else
      {:error, errors}
    end
  end
end
