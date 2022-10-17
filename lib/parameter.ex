defmodule Parameter do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias Parameter.Field
  alias Parameter.Types

  @unknown_field_opts [:error, :ignore]

  @spec load(module() | atom(), map(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def load(schema, input, opts \\ [])

  def load(schema, input, opts) do
    opts = parse_opts(opts)

    case unknow_fields(schema, input, opts[:unknown_field]) do
      :ok -> do_load(schema, input, opts)
      error -> error
    end
  end

  @spec dump(module() | atom(), map()) :: {:ok, any()} | {:error, any()}
  def dump(schema, input) when is_map(input) do
    schema_keys = schema.__param__(:field_keys)
    # TODO: finish dumping method for nested
    Enum.reduce(schema_keys, {%{}, %{}}, fn schema_key, {result, errors} ->
      field = schema.__param__(:field, schema_key)

      {:ok, input_value} = Map.fetch(input, field.name)

      case Field.dump(field, input_value) do
        {:error, error} ->
          errors = Map.put(errors, field.name, error)
          {result, errors}

        {:ok, loaded_value} ->
          result = Map.put(result, field.key, loaded_value)
          {result, errors}
      end
    end)
    |> parse_loaded_input()
  end

  defp do_load(schema, input, opts) when is_map(input) do
    schema_keys = schema.__param__(:field_keys)

    Enum.reduce(schema_keys, {%{}, %{}}, fn schema_key, {result, errors} ->
      field = schema.__param__(:field, schema_key)

      case load_map_value(input, field, opts) do
        {:error, error} ->
          errors = Map.put(errors, field.name, error)
          {result, errors}

        {:ok, nil} ->
          {result, errors}

        {:ok, loaded_value} ->
          result = Map.put(result, field.name, loaded_value)
          {result, errors}
      end
    end)
    |> parse_loaded_input()
    |> parse_to_struct_or_map(schema, struct: opts[:return_struct?])
  end

  defp do_load(type, input, _opts) do
    Types.load(type, input)
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

  defp parse_opts(opts) do
    unknown_field = Keyword.get(opts, :unknown_field, :ignore)

    if unknown_field not in @unknown_field_opts do
      raise("unknown field options should be #{inspect(@unknown_field_opts)}")
    end

    return_struct? = Keyword.get(opts, :struct, false)

    Types.validate!(:boolean, return_struct?)

    [return_struct?: return_struct?, unknown_field: unknown_field]
  end

  defp load_map_value(input, field, opts) do
    case Map.fetch(input, field.key) do
      :error ->
        check_required(field)

      {:ok, nil} ->
        # add nullable check
        check_required(field)

      {:ok, value} ->
        load_type_value(field, value, opts)
    end
  end

  defp check_required(field) do
    cond do
      !is_nil(field.default) ->
        {:ok, field.default}

      field.required ->
        {:error, "is required"}

      true ->
        {:ok, nil}
    end
  end

  defp load_type_value(%Field{type: {:has_one, inner_module}}, value, opts) when is_map(value) do
    do_load(inner_module, value, opts)
  end

  defp load_type_value(%Field{type: {:has_one, _inner_module}}, _value, _opts) do
    {:error, "is not a valid inner data"}
  end

  defp load_type_value(%Field{type: {:has_many, inner_module}}, values, opts)
       when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce({[], []}, fn {value, index}, {acc_list, errors} ->
      inner_module
      |> do_load(value, opts)
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

  defp parse_loaded_input({result, errors}) do
    if errors == %{} do
      result
    else
      {:error, errors}
    end
  end

  defp parse_to_struct_or_map({:error, _error} = result, _schema, _opts), do: result

  defp parse_to_struct_or_map(result, _schema, struct: false), do: {:ok, result}

  defp parse_to_struct_or_map(result, schema, struct: true) do
    {:ok, struct!(schema, result)}
  end
end
