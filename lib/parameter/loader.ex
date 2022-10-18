defmodule Parameter.Loader do
  @moduledoc false

  alias Parameter.Field
  alias Parameter.Types

  @spec load(module() | atom(), map(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def load(schema, input, [struct: struct, unknown: unknown] = opts) when is_map(input) do
    case unknow_fields(schema, input, unknown) do
      :ok ->
        iterate_schema(schema, input, opts)
        |> parse_loaded_input()
        |> parse_to_struct_or_map(schema, struct: struct)

      error ->
        error
    end
  end

  def load(type, input, opts) do
    load_type_value(type, input, opts)
  end

  defp iterate_schema(schema, input, opts) do
    schema_keys = schema.__param__(:field_keys)

    Enum.reduce(schema_keys, {%{}, %{}}, fn schema_key, {result, errors} ->
      field = schema.__param__(:field, schema_key)

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
    case Map.fetch(input, field.key) do
      :error ->
        check_required(field, :ignore)

      {:ok, nil} ->
        check_required(field, nil)

      {:ok, value} ->
        load_type_value(field, value, opts)
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

  defp load_type_value(%Field{type: {:has_one, inner_module}}, value, opts) when is_map(value) do
    load(inner_module, value, opts)
  end

  defp load_type_value(%Field{type: {:has_one, _inner_module}}, _value, _opts) do
    {:error, "invalid inner data type"}
  end

  defp load_type_value(%Field{type: {:has_many, inner_module}}, values, opts)
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

  defp load_type_value(%Field{type: {:has_many, _inner_module}}, _value, _opts) do
    {:error, "invalid list type"}
  end

  defp load_type_value(%Field{type: type, validator: validator}, value, _opts) do
    case Types.load(type, value) do
      {:ok, value} ->
        run_validator(validator, value)

      error ->
        error
    end
  end

  defp load_type_value(type, value, _opts) do
    Types.load(type, value)
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

  defp parse_to_struct_or_map({:error, _error} = result, _schema, _opts), do: result

  defp parse_to_struct_or_map(result, _schema, struct: false), do: result

  defp parse_to_struct_or_map({:ok, result}, schema, struct: true) do
    {:ok, struct!(schema, result)}
  end

  def run_validator(nil, value), do: {:ok, value}

  def run_validator({func, args}, value) do
    case apply(func, [value | [args]]) do
      :ok -> {:ok, value}
      error -> error
    end
  end

  def run_validator(func, value) do
    case func.(value) do
      :ok -> {:ok, value}
      error -> error
    end
  end
end
