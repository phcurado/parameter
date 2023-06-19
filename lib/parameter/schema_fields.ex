defmodule Parameter.SchemaFields do
  @moduledoc false

  alias Parameter.Dumper
  alias Parameter.Field
  alias Parameter.Loader
  alias Parameter.Meta
  alias Parameter.Types
  alias Parameter.Validator

  @spec process_map_value(Meta.t(), Field.t(), Keyword.t()) ::
          {:ok, :ignore} | {:ok, map()} | {:ok, list()} | :ok | {:error, String.t()}
  def process_map_value(meta, field, opts) do
    exclude_fields = Keyword.get(opts, :exclude)

    case field_to_exclude(field.name, exclude_fields) do
      :include ->
        fetch_and_verify_input(meta, field, opts)

      {:exclude, nested_values} ->
        opts = Keyword.put(opts, :exclude, nested_values)
        fetch_and_verify_input(meta, field, opts)

      :exclude ->
        {:ok, :ignore}
    end
  end

  @spec process_list_value(Meta.t(), list(any()), Keyword.t(), boolean()) ::
          {:ok, :ignore} | {:ok, map()} | {:ok, list()} | :ok | {:error, String.t()}
  def process_list_value(meta, values, opts, change_parent? \\ true) do
    values
    |> Enum.with_index()
    |> Enum.reduce({[], %{}}, fn {value, index}, {acc_list, errors} ->
      meta = meta |> Meta.set_input(value)

      meta =
        if change_parent? do
          Meta.set_parent_input(meta, value)
        else
          meta
        end

      case operation_handler(meta, meta.schema, value, opts) do
        {:error, reason} ->
          {acc_list, Map.put(errors, index, reason)}

        {:ok, result} ->
          {[result | acc_list], errors}

        :ok ->
          {acc_list, errors}
      end
    end)
    |> parse_list_values(meta.operation)
  end

  @spec field_handler(Meta.t(), atom | Field.t(), any(), Keyword.t()) ::
          {:ok, :ignore} | {:ok, map()} | {:ok, list()} | :ok | {:error, String.t()}
  def field_handler(_meta, %Field{virtual: true}, _value, _opts) do
    {:ok, :ignore}
  end

  def field_handler(meta, %Field{type: {:map, schema}}, value, opts) when is_map(value) do
    if Types.base_type?(schema) or Types.composite_type?(schema) do
      value
      |> Enum.reduce({%{}, %{}}, fn {key, value}, {acc_map, errors} ->
        case operation_handler(meta, schema, value, opts) do
          {:error, reason} ->
            {acc_map, Map.put(errors, key, reason)}

          {:ok, result} ->
            {Map.put(acc_map, key, result), errors}

          :ok ->
            {acc_map, errors}
        end
      end)
      |> parse_map_values(meta.operation)
    else
      meta
      |> Meta.set_schema(schema)
      |> Meta.set_input(value)
      |> operation_handler(schema, value, opts)
    end
  end

  def field_handler(_meta, %Field{type: {:map, _schema}}, _value, _opts) do
    {:error, "invalid map type"}
  end

  def field_handler(meta, %Field{type: {:array, schema}}, values, opts) when is_list(values) do
    meta
    |> Meta.set_schema(schema)
    |> process_list_value(values, opts, false)
  end

  def field_handler(_meta, %Field{type: {:array, _schema}}, _values, _opts) do
    {:error, "invalid array type"}
  end

  def field_handler(
        %Meta{operation: operation} = meta,
        %Field{validator: validator} = field,
        value,
        opts
      )
      when not is_nil(validator) and operation in [:load, :validate] do
    case operation_handler(meta, field, value, opts) do
      {:ok, value} ->
        validator
        |> run_validator(value)
        |> parse_validator_result(operation)

      :ok ->
        validator
        |> run_validator(value)
        |> parse_validator_result(operation)

      error ->
        error
    end
  end

  def field_handler(meta, %Field{type: _type} = field, value, opts) do
    operation_handler(meta, field, value, opts)
  end

  def field_handler(meta, type, value, opts) do
    operation_handler(meta, %Field{type: type}, value, opts)
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

  defp parse_map_values({_result, errors}, :validate) do
    if errors == %{} do
      :ok
    else
      {:error, errors}
    end
  end

  defp parse_map_values({result, errors}, _operation) do
    if errors == %{} do
      {:ok, result}
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

  defp parse_validator_result({:ok, value}, :load) do
    {:ok, value}
  end

  defp parse_validator_result({:ok, _value}, :validate) do
    :ok
  end

  defp parse_validator_result(error, _operation) do
    error
  end

  defp operation_handler(meta, %Field{type: type} = field, value, opts) do
    cond do
      Types.composite_inner_type?(type) ->
        field_handler(meta, field, value, opts)

      meta.operation == :dump ->
        Types.dump(type, value)

      meta.operation == :load ->
        Types.load(type, value)

      meta.operation == :validate ->
        Types.validate(type, value)
    end
  end

  defp operation_handler(meta, schema, value, opts) do
    cond do
      Types.base_type?(schema) or Types.composite_type?(schema) ->
        field_handler(meta, schema, value, opts)

      meta.operation == :dump ->
        Dumper.dump(meta, opts)

      meta.operation == :load ->
        Loader.load(meta, opts)

      meta.operation == :validate ->
        Validator.validate(meta, opts)
    end
  end

  defp fetch_and_verify_input(meta, field, opts) do
    case fetch_input(meta, field, opts) do
      :error ->
        check_required(field, :ignore, meta.operation)

      {:ok, nil} ->
        check_nil(meta, field, opts)

      {:ok, ""} ->
        check_empty(meta, field, opts)

      {:ok, value} ->
        field_handler(meta, field, value, opts)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_input(%Meta{input: input} = meta, field, opts) do
    if has_double_key?(field, input) do
      {:error, "field is present as atom and string keys"}
    else
      do_fetch_input(meta, field, opts)
    end
  end

  defp has_double_key?(field, input) do
    to_string(field.name) == field.key and Map.has_key?(input, field.name) and
      Map.has_key?(input, field.key)
  end

  defp do_fetch_input(
         %Meta{operation: :load, input: input, parent_input: parent_input} = meta,
         %Field{on_load: on_load} = field,
         opts
       )
       when not is_nil(on_load) do
    value = get_from_key_or_name(input, field)

    case on_load.(value, parent_input) do
      {:ok, value} ->
        field_handler(meta, field, value, opts)

      error ->
        error
    end
  end

  defp do_fetch_input(
         %Meta{operation: :dump, input: input, parent_input: parent_input} = meta,
         %Field{on_dump: on_dump} = field,
         opts
       )
       when not is_nil(on_dump) do
    value = get_from_key_or_name(input, field)

    case on_dump.(value, parent_input) do
      {:ok, value} ->
        field_handler(meta, field, value, opts)

      error ->
        error
    end
  end

  defp do_fetch_input(%Meta{input: input}, field, _opts) do
    fetch_from_key_or_name(input, field)
  end

  defp get_from_key_or_name(input, field) do
    Map.get(input, field.key) || Map.get(input, field.name)
  end

  defp fetch_from_key_or_name(input, field) do
    case Map.fetch(input, field.key) do
      :error -> Map.fetch(input, field.name)
      value -> value
    end
  end

  defp check_required(%Field{required: true, load_default: nil}, value, :load)
       when value in [:ignore, nil] do
    {:error, "is required"}
  end

  defp check_required(%Field{required: true, dump_default: nil}, value, :validate)
       when value in [:ignore, nil] do
    {:error, "is required"}
  end

  defp check_required(%Field{load_default: default}, :ignore, :load) when not is_nil(default) do
    {:ok, default}
  end

  defp check_required(%Field{dump_default: default}, :ignore, :dump) when not is_nil(default) do
    {:ok, default}
  end

  defp check_required(_field, value, :load) do
    {:ok, value}
  end

  defp check_required(_field, value, :dump) do
    {:ok, value}
  end

  defp check_required(_field, _value, :validate) do
    :ok
  end

  defp check_nil(meta, field, opts) do
    if opts[:ignore_nil] do
      check_required(field, :ignore, meta.operation)
    else
      check_required(field, nil, meta.operation)
    end
  end

  defp check_empty(meta, field, opts) do
    if opts[:ignore_empty] do
      check_required(field, :ignore, meta.operation)
    else
      check_required(field, "", meta.operation)
    end
  end
end
