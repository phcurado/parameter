defmodule Parameter do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias Parameter.Field
  alias Parameter.Types

  @unknown_field_opts [:error, :exclude]

  def load(schema, input, opts \\ [])

  def load(schema, input, opts) when is_map(input) do
    unknown_field = Keyword.get(opts, :unknown_field, :exclude)

    if unknown_field not in @unknown_field_opts,
      do: raise("unknown field options should be #{inspect(@unknown_field_opts)}")

    return_struct? = Keyword.get(opts, :struct, false)

    Types.validate!(:boolean, return_struct?)

    schema_keys = schema.__param__(:fields, :keys)

    Enum.reduce(input, {%{}, [], %{}}, fn {key, value}, {result, unknown_fields, errors} ->
      if key in schema_keys do
        field = schema.__param__(:field, key)

        case load_type_value(field, value, opts) |> parse_loaded_input() do
          {:error, error} ->
            errors = Map.put(errors, field.name, error)
            {result, unknown_fields, errors}

          loaded_value ->
            result = Map.put(result, field.name, loaded_value)
            {result, unknown_fields, errors}
        end
      else
        {result, [key | unknown_fields], errors}
      end
    end)
    |> parse_loaded_input()
    |> parse_to_struct_or_map(schema, struct: return_struct?)
  end

  def load(type, input, _opts) do
    Types.load(type, input)
  end

  defp load_type_value(%Field{type: {:map, inner_module}}, value, opts) when is_map(value) do
    load(inner_module, value, opts)
  end

  defp load_type_value(%Field{type: {:map, _inner_module}}, _value, _opts) do
    {:error, "is not a valid map"}
  end

  defp load_type_value(%Field{type: {:array, inner_module}}, values, opts) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce({[], []}, fn {value, index}, {acc_list, errors} ->
      load(inner_module, value, opts)
      |> case do
        {:error, reason} ->
          {acc_list, Keyword.put(errors, :"#{index}", reason)}

        result ->
          {[result | acc_list], errors}
      end
    end)
    |> parse_list_values()
  end

  defp load_type_value(%Field{type: {:array, _inner_module}}, _value, _opts) do
    {:error, "is not a valid array"}
  end

  defp load_type_value(field, value, _opts) do
    Field.load(field, value)
  end

  defp parse_list_values({result, errors}) do
    if errors == [] do
      Enum.reverse(result)
    else
      {:error, Enum.reverse(errors)}
    end
  end

  defp parse_loaded_input({result, _unknown_fields, errors}) do
    if errors == %{} do
      result
    else
      {:error, errors}
    end
  end

  defp parse_loaded_input(result), do: result

  defp parse_to_struct_or_map({:error, _error} = result, _schema, _opts), do: result

  defp parse_to_struct_or_map(result, _schema, struct: false), do: result

  defp parse_to_struct_or_map(result, schema, struct: true) do
    struct!(schema, result)
  end
end
