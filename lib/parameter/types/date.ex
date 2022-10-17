defmodule Parameter.Types.Date do
  @moduledoc """
  Date parameter type
  """

  use Parameter.Parametrizable

  @impl true
  def load(%Date{} = value) do
    {:ok, value}
  end

  def load({_year, _month, _day} = value) do
    case Date.from_erl(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(_value) do
    error_tuple()
  end

  @impl true
  def validate(%Date{}) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid date type"}
end
