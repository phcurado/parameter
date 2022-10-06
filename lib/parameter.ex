defmodule Parameter do
  @moduledoc "README.md"
  |> File.read!()
  |> String.split("<!-- MDOC !-->")
  |> Enum.fetch!(1)

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
