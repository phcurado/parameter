defmodule Parameter.Schema.Compiler do
  @moduledoc false
  alias Parameter.Field

  def compile_schema!(schema) when is_map(schema) do
    for {name, opts} <- schema do
      {type, opts} = Keyword.pop(opts, :type, :string)
      type = compile_type!(type)
      Field.new!([name: name, type: type] ++ opts)
    end
  end

  defp compile_type!({:map, schema}) when is_atom(schema) do
    {:map, schema}
  end

  defp compile_type!({:map, schema}) when is_tuple(schema) do
    {:map, compile_type!(schema)}
  end

  defp compile_type!({:map, schema}) do
    {:map, compile_schema!(schema)}
  end

  defp compile_type!({:array, schema}) when is_atom(schema) do
    {:array, schema}
  end

  defp compile_type!({:array, schema}) when is_tuple(schema) do
    {:array, compile_type!(schema)}
  end

  defp compile_type!({:array, schema}) do
    {:array, compile_schema!(schema)}
  end

  defp compile_type!({_not_assoc, _schema}) do
    raise ArgumentError,
      message:
        "not a valid inner type, please use `{map, inner_type}` or `{array, inner_type}` for nested associations"
  end

  defp compile_type!(type) when is_atom(type) do
    type
  end

  def validate_nested_opts!(opts) do
    keys = Keyword.keys(opts)

    if :default in keys do
      raise ArgumentError, "default cannot be used on nested fields"
    end

    if :load_default in keys do
      raise ArgumentError, "load_default cannot be used on nested fields"
    end

    if :dump_default in keys do
      raise ArgumentError, "dump_default cannot be used on nested fields"
    end

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
