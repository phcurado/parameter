defmodule Parameter.SchemaFields do
  @moduledoc false

  alias Parameter.Dumper
  alias Parameter.Field
  alias Parameter.Loader
  alias Parameter.Types
  alias Parameter.Validator

  @spec process_map_value(atom | Field.t(), map(), Keyword.t(), :load | :dump | :validate) ::
          {:ok, :ignore} | {:ok, map()} | {:ok, list()} | :ok | {:error, String.t()}
  def process_map_value(field, input, opts, operation) do
    exclude_fields = Keyword.get(opts, :exclude)

    case field_to_exclude(field.name, exclude_fields) do
      :include ->
        fetch_and_verify_input(field, input, opts, operation)

      {:exclude, nested_values} ->
        opts = Keyword.put(opts, :exclude, nested_values)
        fetch_and_verify_input(field, input, opts, operation)

      :exclude ->
        {:ok, :ignore}
    end
  end

  @spec field_handler(atom | Field.t(), map(), Keyword.t(), :load | :dump | :validate) ::
          {:ok, :ignore} | {:ok, map()} | {:ok, list()} | :ok | {:error, String.t()}
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

  def field_handler(%Field{type: type, validator: validator}, input, _opts, operation)
      when not is_nil(validator) and operation in [:load, :validate] do
    case operation do
      :load -> Types.load(type, input)
      :validate -> {:ok, input}
    end
    |> case do
      {:ok, value} ->
        validator
        |> run_validator(value)
        |> parse_validator_result(value, operation)

      error ->
        error
    end
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

        :ok ->
          {acc_list, errors}
      end
    end)
    |> parse_list_values(operation)
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

  defp parse_list_values({_result, errors}, :validate) do
    if errors == %{} do
      :ok
    else
      {:error, errors}
    end
  end

  defp parse_list_values({result, errors}, _operation) do
    if errors == %{} do
      {:ok, Enum.reverse(result)}
    else
      {:error, errors}
    end
  end

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

  defp parse_validator_result(:ok, value, :load) do
    {:ok, value}
  end

  defp parse_validator_result(:ok, _value, :validate) do
    :ok
  end

  defp parse_validator_result(error, _value, _operation) do
    error
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

  defp fetch_and_verify_input(field, input, opts, operation) do
    case fetch_input(field, input, operation) do
      :error ->
        check_required(field, :ignore, operation)

      {:ok, nil} ->
        check_required(field, nil, operation)

      {:ok, value} ->
        field_handler(field, value, opts, operation)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_input(field, input, :load) do
    fetched_input = Map.fetch(input, field.key)

    if to_string(field.name) == field.key do
      verify_double_key(fetched_input, field, input)
    else
      fetched_input
    end
  end

  defp fetch_input(field, input, _operation) do
    Map.fetch(input, field.name)
  end

  defp verify_double_key(:error, field, input) do
    Map.fetch(input, field.name)
  end

  defp verify_double_key(fetched_input, field, input) do
    case Map.fetch(input, field.name) do
      {:ok, _value} ->
        {:error, "field is present as atom and string keys"}

      _ ->
        fetched_input
    end
  end

  defp check_required(%Field{required: true, load_default: nil}, _value, operation)
       when operation in [:load, :validate] do
    {:error, "is required"}
  end

  defp check_required(%Field{load_default: default}, value, :load) do
    {:ok, default || value}
  end

  defp check_required(_field, _value, :validate) do
    :ok
  end

  defp check_required(%Field{dump_default: default}, value, :dump) do
    {:ok, default || value}
  end
end
