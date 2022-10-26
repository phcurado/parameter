defmodule Parameter.Types.List do
  @moduledoc """
  List parameter type
  """

  use Parameter.Parametrizable

  @impl true
  def load(list) when is_list(list) do
    {:ok, list}
  end

  def load(_value) do
    error_tuple()
  end

  @impl true
  def validate(list) when is_list(list) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid list type"}
end
