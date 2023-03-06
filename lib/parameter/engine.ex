defmodule Parameter.Engine do
  alias Parameter.Field
  alias Parameter.Schema
  alias Parameter.Types

  @type t :: %__MODULE__{
          schema: module() | nil,
          fields: list(Field.t()),
          valid?: boolean(),
          data: map(),
          changes: map(),
          errors: map(),
          cast_fields: list(atom()),
          operation: :load | :dump | :validate
        }

  defstruct schema: nil,
            fields: [],
            valid?: true,
            data: nil,
            changes: %{},
            errors: %{},
            cast_fields: [],
            operation: :load

  def asdf() do
    %{
      first_name: [type: :string, key: "firstName", required: true],
      info: [type: {:map, %{number: [type: {:array, %{number: [type: :integer]}}]}}],
      address: [type: {:array, %{number: [type: :integer]}}]
    }
    |> Schema.compile!()
    |> load(
      %{
        "firstName" => "Ola",
        "info" => %{
          "number" => [%{"number" => "2"}, %{"number" => "asdajsh"}, %{"number" => "what"}]
        }
      },
      struct: true
    )
    |> apply_operation()
  end

  @spec load(module | list(Field.t()), map(), Keyword.t()) :: t()
  def load(schema_or_fields, params, opts \\ []) do
    fields = Schema.fields(schema_or_fields)

    %__MODULE__{
      schema: Schema.module(schema_or_fields),
      fields: fields,
      data: params,
      cast_fields: infer_cast_fields(fields),
      operation: :load
    }
    |> cast_and_load_params(opts)
  end

  def apply_operation(%__MODULE__{} = engine) do
    engine
    |> case do
      %__MODULE__{valid?: true} ->
        {:ok, fetch_engine_changes(engine)}

      %__MODULE__{valid?: false} ->
        {:error, fetch_engine_errors(engine)}
    end
  end

  defp fetch_engine_changes(%__MODULE__{changes: changes}) when is_map(changes) do
    Enum.reduce(changes, changes, fn
      {field_key, %__MODULE__{} = engine}, acc ->
        Map.put(acc, field_key, fetch_engine_changes(engine))

      {field_key, values}, acc when is_list(values) ->
        Enum.map(values, fn
          %__MODULE__{} = engine ->
            fetch_engine_changes(engine)

          value ->
            value
        end)
        |> then(fn list ->
          Map.put(acc, field_key, list)
        end)

      _, acc ->
        acc
    end)
  end

  defp fetch_engine_errors(%__MODULE__{errors: errors, changes: changes}) do
    Enum.reduce(changes, errors, fn
      {field_key, values}, acc when is_list(values) ->
        values
        |> Enum.with_index()
        |> Enum.filter(fn {engine, _index} -> !engine.valid? end)
        |> Enum.map(fn {engine, index} -> %{index => engine.errors} end)
        |> then(fn list ->
          Map.put(acc, field_key, list)
        end)

      {field_key, %__MODULE__{valid?: false} = engine}, acc ->
        Map.merge(acc, %{field_key => fetch_engine_errors(engine)})

      _, acc ->
        acc
    end)
  end

  def add_change(%__MODULE__{changes: changes} = engine, field, change) do
    %__MODULE__{engine | changes: Map.put(changes, field, change)}
  end

  def get_change(%__MODULE__{changes: changes}, field) do
    Map.get(changes, field)
  end

  def add_error(%__MODULE__{errors: errors} = engine, field, error) do
    %__MODULE__{engine | valid?: false, errors: Map.put(errors, field, error)}
  end

  def operation(%__MODULE__{} = engine, operation) when operation in [:load, :dump, :validate] do
    %__MODULE__{engine | operation: operation}
  end

  defp cast_and_load_params(
         %__MODULE__{
           fields: fields,
           cast_fields: cast_fields
         } = engine,
         opts
       ) do
    fields_to_exclude =
      fields
      |> Enum.map(& &1.name)
      |> Enum.reject(fn field -> field in cast_fields end)

    opts_with_fields_to_exclude = Keyword.merge(opts, exclude: fields_to_exclude)
    cast_params(engine, opts_with_fields_to_exclude)
  end

  defp cast_params(%__MODULE__{fields: fields, cast_fields: cast_fields} = engine, opts) do
    Enum.reduce(cast_fields, engine, fn field_name, engine ->
      field = Enum.find(fields, &(&1.name == field_name))
      fetch_and_verify_input(engine, field, opts)
    end)
  end

  defp infer_cast_fields(fields) do
    Enum.map(fields, & &1.name)
  end

  defp fetch_and_verify_input(engine, field, opts) do
    case fetch_input(engine, field) do
      :error ->
        check_required(engine, field, :ignore)

      {:ok, nil} ->
        check_nil(engine, field, opts)

      {:ok, ""} ->
        check_empty(engine, field, opts)

      {:ok, value} ->
        handle_field(engine, field, value, opts)

      {:error, reason} ->
        add_error(engine, field.name, reason)
    end
  end

  defp fetch_input(%__MODULE__{data: data, operation: :load}, field) do
    fetched_input = Map.fetch(data, field.key)

    if to_string(field.name) == field.key do
      verify_double_key(fetched_input, field, data)
    else
      fetched_input
    end
  end

  defp fetch_input(%__MODULE__{data: data}, field) do
    Map.fetch(data, field.name)
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

  defp check_required(
         %__MODULE__{operation: :load} = engine,
         %Field{name: name, required: true, load_default: nil},
         value
       )
       when value in [:ignore, nil] do
    add_error(engine, name, "is required")
  end

  defp check_required(
         %__MODULE__{operation: :validate} = engine,
         %Field{name: name, required: true, dump_default: nil},
         value
       )
       when value in [:ignore, nil] do
    add_error(engine, name, "is required")
  end

  defp check_required(
         %__MODULE__{operation: :load} = engine,
         %Field{name: name, load_default: default},
         :ignore
       )
       when not is_nil(default) do
    add_change(engine, name, default)
  end

  defp check_required(
         %__MODULE__{operation: :dump} = engine,
         %Field{name: name, dump_default: default},
         :ignore
       )
       when not is_nil(default) do
    add_change(engine, name, default)
  end

  defp check_required(%__MODULE__{} = engine, _field, :ignore) do
    engine
  end

  defp check_required(%__MODULE__{} = engine, %Field{name: name}, value) do
    add_change(engine, name, value)
  end

  defp check_nil(engine, field, opts) do
    if opts[:ignore_nil] do
      check_required(engine, field, :ignore)
    else
      check_required(engine, field, nil)
    end
  end

  defp check_empty(engine, field, opts) do
    if opts[:ignore_empty] do
      check_required(engine, field, :ignore)
    else
      check_required(engine, field, "")
    end
  end

  defp handle_field(engine, %Field{virtual: true}, _value, _opts) do
    engine
  end

  defp handle_field(engine, %Field{type: {:array, schema}} = field, values, opts)
       when is_list(values) do
    values
    |> Enum.reverse()
    |> Enum.reduce(engine, fn value, engine ->
      case handle_method(engine, schema, value, opts) do
        %__MODULE__{valid?: false} = inner_engine ->
          field_changes = get_change(engine, field.name) || []
          engine = add_change(engine, field.name, [inner_engine | field_changes])
          %__MODULE__{engine | valid?: false}

        %__MODULE__{valid?: true} = inner_engine ->
          field_changes = get_change(engine, field.name) || []
          add_change(engine, field.name, [inner_engine | field_changes])
      end
    end)
  end

  defp handle_field(engine, %Field{name: name, type: {:array, _schema}}, _values, _opts) do
    add_error(engine, name, "invalid array type")
  end

  defp handle_field(engine, %Field{type: {:map, schema}} = field, value, opts)
       when is_map(value) do
    handle_field(engine, schema, value, opts) |> IO.inspect()
    # value
    # |> Enum.reduce(engine, fn {key, value}, engine ->
    #   case handle_method(engine, schema, value, opts) do
    #     %__MODULE__{valid?: false} = inner_engine ->
    #       IO.inspect("whats happening")
    #       IO.inspect(key)
    #       IO.inspect(inner_engine)

    #     %__MODULE__{valid?: true} = inner_engine ->
    #       IO.inspect("Im valid ")
    #       IO.inspect(key)
    #       IO.inspect(key)
    #       IO.inspect(inner_engine)
    #       # add_change(engine, field.name, inner_engine)
    #   end
    # end)

    # case handle_method(engine, schema, value, opts) do
    #   %__MODULE__{valid?: false} = inner_engine ->
    #     %__MODULE__{
    #       engine
    #       | changes: Map.put(engine.changes, field.name, inner_engine),
    #         valid?: false
    #     }

    #   %__MODULE__{valid?: true} = inner_engine ->
    #     add_change(engine, field.name, inner_engine)
    # end
  end

  defp handle_field(engine, %Field{name: name, type: {:map, _schema}}, _values, _opts) do
    add_error(engine, name, "invalid map type")
  end

  defp handle_field(
         %__MODULE__{operation: :load} = engine,
         %Field{type: type} = field,
         value,
         _opts
       ) do
    case Types.load(type, value) do
      {:error, error} ->
        add_error(engine, field.name, error)

      {:ok, loaded_value} ->
        add_change(engine, field.name, loaded_value)
    end
  end

  defp handle_method(%__MODULE__{operation: :load}, {:map, schema}, params, opts) do
    load(schema, params, opts)
    |> IO.inspect()
  end

  defp handle_method(%__MODULE__{operation: :load}, schema, params, opts) do
    load(schema, params, opts)
  end
end

defimpl Inspect, for: Parameter.Engine do
  import Inspect.Algebra

  def inspect(engine, opts) do
    list =
      for attr <- [:schema, :fields, :cast_fields, :changes, :errors, :data, :valid?] do
        {attr, Map.get(engine, attr)}
      end

    container_doc("#Parameter.Engine<", list, ">", opts, fn
      {:schema, schema}, opts ->
        concat("schema: ", to_doc(schema, opts))

      {:fields, fields}, opts ->
        concat("fields: ", fields(fields, opts))

      {:cast_fields, cast_fields}, opts ->
        concat("cast_fields: ", to_doc(cast_fields, opts))

      {:changes, changes}, opts ->
        concat("changes: ", to_doc(changes, opts))

      {:data, data}, _opts ->
        concat("data: ", to_doc(data, opts))

      {:errors, errors}, opts ->
        concat("errors: ", to_doc(errors, opts))

      {:valid?, valid?}, opts ->
        concat("valid?: ", to_doc(valid?, opts))
    end)
  end

  # defp to_struct(%{__struct__: struct}, _opts), do: "#" <> Kernel.inspect(struct) <> "<>"
  # defp to_struct(other, opts), do: to_doc(other, opts)

  defp fields(fields, opts) when is_list(fields) do
    Enum.reduce(fields, [], fn %Parameter.Field{name: name}, acc ->
      [name | acc]
    end)
    |> Enum.reverse()
    |> to_doc(opts)
  end

  defp fields(module, opts) do
    to_doc(module, opts)
  end
end
