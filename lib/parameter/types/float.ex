defmodule Parameter.Types.Float do
  @moduledoc """
  Float parameter type
  """

  @behaviour Parameter.Parametrizable

  @impl true
  def load(value) when is_float(value) do
    {:ok, value}
  end

  def load(value) when is_binary(value) do
    case Float.parse(value) do
      {float, ""} -> {:ok, float}
      _error -> error_tuple()
    end
  end

  def load(value) when is_integer(value) do
    {:ok, value / 1}
  end

  def load(_value) do
    error_tuple()
  end

  @impl true
  def validate(value) when is_float(value) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid float type"}
end
