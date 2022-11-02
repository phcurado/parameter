defmodule Parameter.Dumper do
  @moduledoc false

  alias Parameter.ExcludeFields
  alias Parameter.Field
  alias Parameter.Types

  @type opts :: [exclude: list()]

  @spec dump(module() | atom(), map(), opts) :: {:ok, any()} | {:error, any()}
  def dump(schema, input, opts) when is_map(input) do
    schema_keys = schema.__param__(:field_keys)

    Enum.reduce(schema_keys, {%{}, %{}}, fn schema_key, {result, errors} ->
      field = schema.__param__(:field, key: schema_key)

      case dump_map_value(field, input, opts) do
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

  def dump(type, input, opts) do
    dump_type_value(type, input, opts)
  end

  defp dump_map_value(field, input, opts) do
    exclude_fields = Keyword.get(opts, :exclude)

    case ExcludeFields.field_to_exclude(field.name, exclude_fields) do
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
    case Map.fetch(input, field.name) do
      :error ->
        {:ok, :ignore}

      {:ok, nil} ->
        {:ok, nil}

      {:ok, value} ->
        dump_type_value(field, value, opts)
    end
  end

  defp dump_type_value(%Field{virtual: true}, _value, _opts) do
    {:ok, :ignore}
  end

  defp dump_type_value(%Field{type: {:has_one, inner_module}}, value, opts) when is_map(value) do
    dump(inner_module, value, opts)
  end

  defp dump_type_value(%Field{type: {:has_one, _inner_module}}, _value, _opts) do
    {:error, "invalid inner data type"}
  end

  defp dump_type_value(%Field{type: {:has_many, inner_module}}, values, opts)
       when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce({[], []}, fn {value, index}, {acc_list, errors} ->
      case dump(inner_module, value, opts) do
        {:error, reason} ->
          {acc_list, [{index, reason} | errors]}

        {:ok, result} ->
          {[result | acc_list], errors}
      end
    end)
    |> parse_list_values()
  end

  defp dump_type_value(%Field{type: {:has_many, _inner_module}}, _value, _opts) do
    {:error, "invalid list type"}
  end

  defp dump_type_value(%Field{type: type}, value, _opts) do
    Types.dump(type, value)
  end

  defp dump_type_value(type, value, _opts) do
    Types.dump(type, value)
  end

  defp parse_list_values({result, errors}) do
    if errors == [] do
      {:ok, Enum.reverse(result)}
    else
      {:error, Enum.reverse(errors)}
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
