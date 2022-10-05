defmodule Parameter.Types.Integer do
  @moduledoc """
  Integer parameter type
  """

  use Parameter.Types

  def load(value) when is_integer(value) do
    value
  end

  def load(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _error -> error_tuple()
    end
  end

  def load(_value) do
    error_tuple()
  end

  def validate(value) when is_integer(value) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid integer type"}
end
