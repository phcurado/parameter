defmodule Parameter.Types.Map do
  @moduledoc """
  Map parameter type
  """

  @behaviour Parameter.Parametrizable

  @impl true
  def load(map, opts \\ [])

  def load(map, _opts) when is_map(map) do
    {:ok, map}
  end

  def load(_value, _opts) do
    error_tuple()
  end

  @impl true
  def validate(map, opts \\ [])

  def validate(map, _opts) when is_map(map) do
    :ok
  end

  def validate(_value, _opts) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid map type"}
end
