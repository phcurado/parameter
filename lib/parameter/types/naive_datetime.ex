defmodule Parameter.Types.NaiveDateTime do
  @moduledoc """
  NaiveDateTime parameter type
  """

  use Parameter.Types

  def load(%NaiveDateTime{} = value) do
    value
  end

  def load({{_year, _month, _day}, {_hour, _min, _sec}} = value) do
    case NaiveDateTime.from_erl(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> date
    end
  end

  def load(value) when is_binary(value) do
    case NaiveDateTime.from_iso8601(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> date
    end
  end

  def load(_value) do
    error_tuple()
  end

  def validate(%NaiveDateTime{}) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid naive_datetime type"}
end
