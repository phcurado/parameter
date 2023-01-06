defmodule Parameter.Types.Array do
  @moduledoc """
  Array parameter type
  """

  use Parameter.Parametrizable

  @impl true
  def load(array) when is_list(array) do
    {:ok, array}
  end

  def load(_value) do
    error_tuple()
  end

  @impl true
  def validate(array) when is_list(array) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid array type"}
end
