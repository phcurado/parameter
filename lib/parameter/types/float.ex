defmodule Parameter.Types.Float do
  @moduledoc """
  Float parameter type
  """

  use Parameter.Types

  def load(value) when is_float(value) do
    value
  end

  def load(value) when is_binary(value) do
    case Float.parse(value) do
      {float, ""} -> float
      _error -> error_tuple()
    end
  end

  def load(value) when is_integer(value) do
    value / 1
  end

  def load(_value) do
    error_tuple()
  end

  def validate(value) when is_float(value) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid float type"}
end
