defmodule Parameter.SchemaFields do
  @moduledoc false

  alias Parameter.Dumper
  alias Parameter.Field
  alias Parameter.Loader
  alias Parameter.Types
  alias Parameter.Validator

  @spec process_map_value(atom | Field.t(), map(), Keyword.t(), :load | :dump | :validate) ::
          {:ok, :ignore} | {:ok, map()} | {:ok, list()} | {:error, String.t()}
  def process_map_value(field, input, opts, action) do
    exclude_fields = Keyword.get(opts, :exclude)

    case field_to_exclude(field.name, exclude_fields) do
      :include ->
        fetch_and_verify_input(field, input, opts, action)

      {:exclude, nested_values} ->
        opts = Keyword.put(opts, :exclude, nested_values)
        fetch_and_verify_input(field, input, opts, action)

      :exclude ->
        {:ok, :ignore}
    end
  end

  @spec field_handler(atom | Field.t(), map(), Keyword.t(), :load | :dump | :validate) ::
          {:ok, :ignore} | {:ok, map()} | {:ok, list()} | {:error, String.t()}
  def field_handler(%Field{virtual: true}, _input, _opts, _operation) do
    {:ok, :ignore}
  end

  def field_handler(%Field{type: {:has_one, schema}}, input, opts, operation)
      when is_map(input) do
    operation_handler(schema, input, opts, operation)
  end

  def field_handler(%Field{type: {:has_one, _schema}}, _input, _opts, _operation) do
    {:error, "invalid inner data type"}
  end

  def field_handler(%Field{type: {:has_many, schema}}, inputs, opts, operation) do
    list_field_handler(schema, inputs, opts, operation)
  end

  def field_handler(%Field{type: type, validator: validator}, input, _opts, :load) do
    case Types.load(type, input) do
      {:ok, value} ->
        run_validator(validator, value)

      error ->
        error
    end
  end

  def field_handler(%Field{validator: validator}, input, _opts, :validate) do
    run_validator(validator, input)
  end

  def field_handler(%Field{type: type}, input, _opts, operation) do
    operation_type_handler(type, input, operation)
  end

  def field_handler(type, input, _opts, operation) do
    operation_type_handler(type, input, operation)
  end

  @spec list_field_handler(module(), list(map()), Keyword.t(), atom()) ::
          {:error, list()} | {:ok, list()}
  def list_field_handler(schema, inputs, opts, operation)
      when is_list(inputs) do
    inputs
    |> Enum.with_index()
    |> Enum.reduce({[], %{}}, fn {value, index}, {acc_list, errors} ->
      case operation_handler(schema, value, opts, operation) do
        {:error, reason} ->
          {acc_list, Map.put(errors, index, reason)}

        {:ok, result} ->
          {[result | acc_list], errors}
      end
    end)
    |> parse_list_values()
  end

  def list_field_handler(_schema, _inputs, _opts, _operation) do
    {:error, "invalid list type"}
  end

  @spec field_to_exclude(atom() | binary(), list()) :: :exclude | :include | {:exclude, list()}
  def field_to_exclude(field_name, exclude_fields) when is_list(exclude_fields) do
    exclude_fields
    |> Enum.find(fn
      {key, _value} -> field_name == key
      key -> field_name == key
    end)
    |> case do
      nil -> :include
      {_key, nested_values} -> {:exclude, nested_values}
      _ -> :exclude
    end
  end

  def field_to_exclude(_field_name, _exclude_fields), do: :include

  defp parse_list_values({result, errors}) do
    if errors == %{} do
      {:ok, Enum.reverse(result)}
    else
      {:error, errors}
    end
  end

  defp run_validator(nil, value), do: {:ok, value}

  defp run_validator({func, args}, value) do
    case apply(func, [value | [args]]) do
      :ok -> {:ok, value}
      error -> error
    end
  end

  defp run_validator(func, value) do
    case func.(value) do
      :ok -> {:ok, value}
      error -> error
    end
  end

  defp operation_handler(schema, input, opts, operation) do
    case operation do
      :dump -> Dumper.dump(schema, input, opts)
      :load -> Loader.load(schema, input, opts)
      :validate -> Validator.validate(schema, input, opts)
    end
  end

  defp operation_type_handler(type, input, operation) do
    case operation do
      :dump -> Types.dump(type, input)
      :load -> Types.load(type, input)
      :validate -> Types.validate(type, input)
    end
  end

  defp fetch_and_verify_input(field, input, opts, action) do
    key =
      case action do
        :load -> field.key
        :dump -> field.name
        :validate -> field.name
      end

    case Map.fetch(input, key) do
      :error ->
        check_required(field, :ignore, action)

      {:ok, nil} ->
        check_required(field, nil, action)

      {:ok, value} ->
        field_handler(field, value, opts, action)
    end
  end

  defp check_required(%Field{required: true, load_default: nil}, _value, operation)
       when operation in [:load, :validate] do
    {:error, "is required"}
  end

  defp check_required(%Field{load_default: default}, value, operation)
       when operation in [:load, :validate] do
    {:ok, default || value}
  end

  defp check_required(%Field{dump_default: default}, value, :dump) do
    {:ok, default || value}
  end
end
