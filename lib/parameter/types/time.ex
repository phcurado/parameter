defmodule Parameter.Types.Time do
  @moduledoc """
  Time parameter type
  """

  use Parameter.Parametrizable

  @impl true
  def load(%Time{} = value) do
    {:ok, value}
  end

  def load({_hour, _min, _sec} = value) do
    case Time.from_erl(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(value) when is_binary(value) do
    case Time.from_iso8601(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(_value) do
    error_tuple()
  end

  @impl true
  def validate(%Time{}) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid time type"}
end
