defmodule Parameter.Dumper do
  @moduledoc false

  alias Parameter.Field
  alias Parameter.Types

  @spec dump(module() | atom(), map()) :: {:ok, any()} | {:error, any()}
  def dump(schema, input) when is_map(input) do
    schema_keys = schema.__param__(:field_keys)

    Enum.reduce(schema_keys, {%{}, %{}}, fn schema_key, {result, errors} ->
      field = schema.__param__(:field, schema_key)

      case dump_map_value(field, input) do
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

  def dump(type, input) do
    dump_type_value(type, input)
  end

  defp dump_map_value(field, input) do
    case Map.fetch(input, field.name) do
      :error ->
        {:ok, :ignore}

      {:ok, nil} ->
        {:ok, nil}

      {:ok, value} ->
        dump_type_value(field, value)
    end
  end

  defp dump_type_value(%Field{type: {:has_one, inner_module}}, value) when is_map(value) do
    dump(inner_module, value)
  end

  defp dump_type_value(%Field{type: {:has_one, _inner_module}}, _value) do
    {:error, "invalid inner data type"}
  end

  defp dump_type_value(%Field{type: {:has_many, inner_module}}, values)
       when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce({[], []}, fn {value, index}, {acc_list, errors} ->
      case dump(inner_module, value) do
        {:error, reason} ->
          {acc_list, Keyword.put(errors, :"#{index}", reason)}

        {:ok, result} ->
          {[result | acc_list], errors}
      end
    end)
    |> parse_list_values()
  end

  defp dump_type_value(%Field{type: {:has_many, _inner_module}}, _value) do
    {:error, "invalid list type"}
  end

  defp dump_type_value(%Field{type: type}, value) do
    Types.dump(type, value)
  end

  defp dump_type_value(type, value) do
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
