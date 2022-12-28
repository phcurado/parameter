defmodule Parameter.Schema.Compiler do
  @moduledoc false

  def fetch_nested_opts!(opts) do
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

    if :load_func in keys do
      raise ArgumentError, "load_func cannot be used on nested fields"
    end

    if :dump_func in keys do
      raise ArgumentError, "dump_func cannot be used on nested fields"
    end

    opts
  end
end
