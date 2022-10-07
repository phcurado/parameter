defmodule Parameter.Types.NaiveDateTime do
  @moduledoc """
  NaiveDateTime parameter type
  """

  @behaviour Parameter.Parametrizable

  @impl true
  def load(date, opts \\ [])

  def load(%NaiveDateTime{} = value, _opts) do
    {:ok, value}
  end

  def load({{_year, _month, _day}, {_hour, _min, _sec}} = value, _opts) do
    case NaiveDateTime.from_erl(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(value, _opts) when is_binary(value) do
    case NaiveDateTime.from_iso8601(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(_value, _opts) do
    error_tuple()
  end

  @impl true
  def validate(date, opts \\ [])

  def validate(%NaiveDateTime{}, _opts) do
    :ok
  end

  def validate(_value, _opts) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid naive_datetime type"}
end
