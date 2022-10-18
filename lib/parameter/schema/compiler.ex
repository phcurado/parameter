defmodule Parameter.Schema.Compiler do
  @moduledoc """
  Compile schema options
  """

  def fetch_nested_opts!(opts) do
    keys = Keyword.keys(opts)

    if :default in keys do
      raise ArgumentError, "default cannot be used on nested field"
    end

    if :validator in keys do
      raise ArgumentError, "validator cannot be used on nested field"
    end

    opts
  end
end
