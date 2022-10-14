defmodule Parameter do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias Parameter.Field
  alias Parameter.Types

  @unknown_field_opts [:error, :exclude]

  @spec load(module() | atom(), map(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def load(schema, input, opts \\ [])

  def load(schema, input, opts) when is_map(input) do
    unknown_field = Keyword.get(opts, :unknown_field, :exclude)

    if unknown_field not in @unknown_field_opts do
      raise("unknown field options should be #{inspect(@unknown_field_opts)}")
    end

    return_struct? = Keyword.get(opts, :struct, false)

    Types.validate!(:boolean, return_struct?)

    schema_keys = schema.__param__(:field_keys)

    Enum.reduce(schema_keys, {%{}, [], %{}}, fn schema_key, {result, unknown_fields, errors} ->
      field = schema.__param__(:field, schema_key)

      case load_map_value(input, field, opts) do
        {:error, error} ->
          errors = Map.put(errors, field.name, error)
          {result, unknown_fields, errors}
        {:ok, nil} ->
          {result, unknown_fields, errors}
        {:ok, loaded_value} ->
          result = Map.put(result, field.name, loaded_value)
          {result, unknown_fields, errors}
      end
    end)
    |> parse_loaded_input()
    |> parse_to_struct_or_map(schema, struct: return_struct?)
  end

  def load(type, input, _opts) do
    Types.load(type, input)
  end

  defp load_map_value(input, field, opts) do
    case Map.fetch(input, field.key) do
      :error ->
        check_required(field)

      {:ok, nil} ->
        # TODO: add nullable check
        check_required(field)

      {:ok, value} ->
        field
        |> load_type_value(value, opts)
        |> parse_loaded_input()
    end
  end

  defp check_required(field) do
    cond do
      !is_nil(field.default) ->
        {:ok, field.default}

      field.required ->
        {:error, "is missing"}

      true ->
        {:ok, nil}
    end
  end

  defp load_type_value(%Field{type: {:has_one, inner_module}}, value, opts) when is_map(value) do
    load(inner_module, value, opts)
  end

  defp load_type_value(%Field{type: {:has_one, _inner_module}}, _value, _opts) do
    {:error, "is not a valid inner data"}
  end

  defp load_type_value(%Field{type: {:have_many, inner_module}}, values, opts)
       when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce({[], []}, fn {value, index}, {acc_list, errors} ->
      inner_module
      |> load(value, opts)
      |> case do
        {:error, reason} ->
          {acc_list, Keyword.put(errors, :"#{index}", reason)}

        {:ok, result} ->
          {[result | acc_list], errors}
      end
    end)
    |> parse_list_values()
  end

  defp load_type_value(%Field{type: {:have_many, _inner_module}}, _value, _opts) do
    {:error, "is not a valid list"}
  end

  defp load_type_value(field, value, _opts) do
    Field.load(field, value)
  end

  defp parse_list_values({result, errors}) do
    if errors == [] do
      {:ok, Enum.reverse(result)}
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

  defp parse_to_struct_or_map(result, _schema, struct: false), do: {:ok, result}

  defp parse_to_struct_or_map(result, schema, struct: true) do
    {:ok, struct!(schema, result)}
  end
end
