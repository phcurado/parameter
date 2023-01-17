defmodule Parameter.Operator do
  alias Parameter.Field
  alias Parameter.Schema

  @type t :: %__MODULE__{
          schema: module() | nil,
          valid?: boolean(),
          data: map(),
          changes: map(),
          errors: map(),
          cast_fields: list(atom())
        }

  defstruct schema: nil,
            valid?: false,
            data: nil,
            changes: %{},
            errors: %{},
            cast_fields: []

  @spec cast(module() | list(Field.t()), map(), list(atom())) :: t()
  def cast(schema, params, cast_fields) do
    %__MODULE__{
      schema: schema,
      data: params,
      cast_fields: cast_fields
    }
  end

  @spec cast(module() | list(Field.t()), map()) :: t()
  def cast(schema, params) do
    schema_fields = Schema.fields(schema)

    %__MODULE__{
      schema: schema,
      data: params,
      cast_fields: infer_cast_fields(schema_fields)
    }
  end

  def load(
        %__MODULE__{
          schema: schema,
          data: data,
          cast_fields: cast_fields
        } = operator,
        opts \\ []
      ) do
    schema_fields = Schema.fields(schema)

    fields_to_exclude =
      schema_fields
      |> Enum.map(& &1.name)
      |> Enum.reject(fn field -> field in cast_fields end)

    opts_with_fields_to_exclude = Keyword.merge(opts, exclude: fields_to_exclude)

    case Parameter.load(schema, data, opts_with_fields_to_exclude) do
      {:ok, loaded} ->
        %__MODULE__{operator | valid?: true, changes: loaded}
        |> load_assoc(opts)

      {:error, errors} ->
        %__MODULE__{operator | valid?: false, errors: errors}
        |> load_assoc(opts)
    end
  end

  def load_assoc(%__MODULE__{schema: schema, data: data} = operator, opts \\ []) do
    schema_fields = Schema.fields(schema)
    assoc_fields = Schema.assoc_fields(schema)

    Enum.reduce(assoc_fields, operator, fn assoc_field, operator ->
      %Field{name: name, key: key, type: {assoc_type, schema}} =
        Enum.find(schema_fields, &(&1.name == assoc_field.name))

      opts =
        if assoc_type == :array do
          Keyword.merge(opts, many: true)
        else
          opts
        end

      case schema |> cast(Map.get(data, key)) |> load(opts) do
        %__MODULE__{valid?: true} = result ->
          %__MODULE__{operator | changes: Map.put(operator.changes, name, result)}

        %__MODULE__{valid?: false} = result ->
          %__MODULE__{operator | valid?: false, changes: Map.put(operator.changes, name, result)}
      end
    end)
  end

  defp infer_cast_fields(fields) do
    fields
    |> Enum.filter(fn
      %Parameter.Field{type: {:map, _nested}} -> false
      %Parameter.Field{type: {:array, _nested}} -> false
      _ -> true
    end)
    |> Enum.map(& &1.name)
  end
end

defimpl Inspect, for: Parameter.Operator do
  import Inspect.Algebra

  def inspect(operator, opts) do
    list =
      for attr <- [:schema, :cast_fields, :changes, :errors, :data, :valid?] do
        {attr, Map.get(operator, attr)}
      end

    container_doc("#Parameter.Operator<", list, ">", opts, fn
      {:schema, schema}, opts ->
        concat("schema: ", schema_field(schema, opts))

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

  defp schema_field(fields, opts) when is_list(fields) do
    Enum.reduce(fields, [], fn %Parameter.Field{name: name}, acc ->
      [name | acc]
    end)
    |> to_doc(opts)
  end

  defp schema_field(module, opts) do
    to_doc(module, opts)
  end
end
