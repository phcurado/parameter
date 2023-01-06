defmodule Parameter.Loader do
  @moduledoc false

  alias Parameter.Meta
  alias Parameter.Schema
  alias Parameter.SchemaFields

  @type opts :: [
          struct: boolean(),
          unknow_fields: :error | :ignore,
          exclude: list(),
          ignore_nil: boolean(),
          many: boolean()
        ]

  @spec load(Meta.t(), opts) :: {:ok, any()} | {:error, any()}
  def load(%Meta{input: input} = meta, opts) when is_map(input) do
    unknown = Keyword.get(opts, :unknown)
    struct = Keyword.get(opts, :struct)

    case unknow_fields(meta, unknown) do
      :ok ->
        iterate_schema(meta, opts)
        |> parse_loaded_input()
        |> parse_to_struct_or_map(meta, struct: struct)

      error ->
        error
    end
  end

  def load(%Meta{input: input} = meta, opts) when is_list(input) do
    if Keyword.get(opts, :many) do
      SchemaFields.process_list_value(meta, input, opts)
    else
      {:error,
       "received a list with `many: false`, if a list is expected pass `many: true` on options"}
    end
  end

  defp iterate_schema(meta, opts) do
    schema_keys = Schema.field_keys(meta.schema)

    Enum.reduce(schema_keys, {%{}, %{}}, fn schema_key, {result, errors} ->
      field = Schema.field_key(meta.schema, schema_key)

      case SchemaFields.process_map_value(meta, field, opts) do
        {:error, error} ->
          errors = Map.put(errors, field.name, error)
          {result, errors}

        {:ok, :ignore} ->
          {result, errors}

        {:ok, loaded_value} ->
          result = Map.put(result, field.name, loaded_value)
          {result, errors}
      end
    end)
  end

  defp unknow_fields(%Meta{schema: schema, input: input}, :error) do
    schema_keys = Schema.field_keys(schema)

    unknow_fields =
      Enum.reduce(input, %{}, fn {key, _value}, acc ->
        if key in schema_keys do
          acc
        else
          Map.put(acc, key, "unknown field")
        end
      end)

    if unknow_fields == %{} do
      :ok
    else
      {:error, unknow_fields}
    end
  end

  defp unknow_fields(_meta, _ignore), do: :ok

  defp parse_loaded_input({result, errors}) do
    if errors == %{} do
      {:ok, result}
    else
      {:error, errors}
    end
  end

  defp parse_to_struct_or_map({:error, _error} = result, _meta, _opts), do: result

  defp parse_to_struct_or_map(result, _meta, struct: false), do: result

  defp parse_to_struct_or_map({:ok, result}, %Meta{schema: schema}, struct: true)
       when is_atom(schema) do
    {:ok, struct!(schema, result)}
  end

  defp parse_to_struct_or_map(result, _meta, _opts), do: result
end
