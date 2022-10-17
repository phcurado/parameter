defmodule Parameter.Types.DateTime do
  @moduledoc """
  DateTime parameter type
  """

  use Parameter.Parametrizable

  @impl true
  def load(%DateTime{} = value) do
    {:ok, value}
  end

  def load(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date, _offset} -> {:ok, date}
    end
  end

  def load(_value) do
    error_tuple()
  end

  @impl true
  def validate(%DateTime{}) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid datetime type"}
end
