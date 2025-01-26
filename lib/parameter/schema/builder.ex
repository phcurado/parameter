defmodule Parameter.Schema.Builder do
  @moduledoc false
  alias Parameter.Field
  alias Parameter.Types

  def build!(schema) when is_map(schema) do
    for {name, opts} <- schema do
      {type, opts} = Keyword.pop(opts, :type, :string)
      type = compile_type!(type)

      field = Field.new!([name: name, type: type] ++ opts)

      case validate_default(field) do
        :ok -> field
        {:error, reason} -> raise ArgumentError, message: inspect(reason)
      end
    end
  end

  def build!(schema) when is_atom(schema) or is_list(schema) do
    Parameter.Schema.fields(schema)
  end

  defp compile_type!({type, schema}) when is_tuple(schema) do
    {type, compile_type!(schema)}
  end

  defp compile_type!({type, schema}) do
    if Types.composite_type?(type) do
      {type, build!(schema)}
    else
      raise ArgumentError,
        message:
          "not a valid inner type, please use `{map, inner_type}` or `{array, inner_type}` for nested associations"
    end
  end

  defp compile_type!(type) when is_atom(type) do
    type
  end

  defp validate_default(
         %Field{default: default, load_default: load_default, dump_default: dump_default} = field
       ) do
    with :ok <- validate_default(field, default),
         :ok <- validate_default(field, load_default),
         do: validate_default(field, dump_default)
  end

  defp validate_default(_field, nil) do
    :ok
  end

  defp validate_default(%Field{name: name} = field, default_value) do
    Parameter.validate([field], %{name => default_value})
  end

  def validate_nested_opts!(opts) do
    keys = Keyword.keys(opts)

    if :validator in keys do
      raise ArgumentError, "validator cannot be used on nested fields"
    end

    if :on_load in keys do
      raise ArgumentError, "on_load cannot be used on nested fields"
    end

    if :on_dump in keys do
      raise ArgumentError, "on_dump cannot be used on nested fields"
    end

    opts
  end
end
