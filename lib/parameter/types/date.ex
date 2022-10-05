defmodule Parameter.Types.Date do
  @moduledoc """
  Date parameter type
  """

  use Parameter.Types

  def load(%Date{} = value) do
    value
  end

  def load({_year, _month, _day} = value) do
    case Date.from_erl(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> date
    end
  end

  def load(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> date
    end
  end

  def load(_value) do
    error_tuple()
  end

  def validate(%Date{}) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid date type"}
end
