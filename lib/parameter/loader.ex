defmodule Parameter.Loader do
  @moduledoc false

  alias Parameter.SchemaFields

  @type opts :: [struct: boolean(), unknow_fields: :error | :ignore, exclude: list()]

  @spec load(module() | atom(), map() | list(map()), opts) :: {:ok, any()} | {:error, any()}
  def load(schema, input, opts) when is_map(input) do
    unknown = Keyword.get(opts, :unknown)
    struct = Keyword.get(opts, :struct)

    case unknow_fields(schema, input, unknown) do
      :ok ->
        iterate_schema(schema, input, opts)
        |> parse_loaded_input()
        |> parse_to_struct_or_map(schema, struct: struct)

      error ->
        error
    end
  end

  def load(schema, input, opts) when is_list(input) do
    if Keyword.get(opts, :many) do
      SchemaFields.list_field_handler(schema, input, opts, :load)
    else
      {:error,
       "received a list with `many: false`, if a list is expected pass `many: true` on options"}
    end
  end

  def load(type, input, opts) do
    SchemaFields.field_handler(type, input, opts, :load)
  end

  defp iterate_schema(schema, input, opts) do
    schema_keys = schema.__param__(:field_keys)

    Enum.reduce(schema_keys, {%{}, %{}}, fn schema_key, {result, errors} ->
      field = schema.__param__(:field, key: schema_key)

      case load_map_value(field, input, opts) do
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

  defp unknow_fields(schema, input, :error) do
    schema_keys = schema.__param__(:field_keys)

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

  defp unknow_fields(_schema, _input, _ignore), do: :ok

  defp load_map_value(field, input, opts) do
    exclude_fields = Keyword.get(opts, :exclude)

    case SchemaFields.field_to_exclude(field.name, exclude_fields) do
      :include ->
        fetch_and_verify_input(field, input, opts)

      {:exclude, nested_values} ->
        opts = Keyword.put(opts, :exclude, nested_values)
        fetch_and_verify_input(field, input, opts)

      :exclude ->
        {:ok, :ignore}
    end
  end

  defp fetch_and_verify_input(field, input, opts) do
    case Map.fetch(input, field.key) do
      :error ->
        check_required(field, :ignore)

      {:ok, nil} ->
        check_required(field, nil)

      {:ok, value} ->
        SchemaFields.field_handler(field, value, opts, :load)
    end
  end

  defp check_required(field, action) do
    cond do
      !is_nil(field.default) ->
        {:ok, field.default}

      field.required ->
        {:error, "is required"}

      true ->
        {:ok, action}
    end
  end

  defp parse_loaded_input({result, errors}) do
    if errors == %{} do
      {:ok, result}
    else
      {:error, errors}
    end
  end

  defp parse_to_struct_or_map({:error, _error} = result, _schema, _opts), do: result

  defp parse_to_struct_or_map(result, _schema, struct: false), do: result

  defp parse_to_struct_or_map({:ok, result}, schema, struct: true) do
    {:ok, struct!(schema, result)}
  end
end
