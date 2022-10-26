defmodule Parameter.Types.Map do
  @moduledoc """
  Map parameter type
  """

  use Parameter.Parametrizable

  @impl true
  def load(map) when is_map(map) do
    {:ok, map}
  end

  def load(_value) do
    error_tuple()
  end

  @impl true
  def validate(map) when is_map(map) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid map type"}
end
