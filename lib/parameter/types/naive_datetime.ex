defmodule Parameter.Types.NaiveDateTime do
  @moduledoc """
  NaiveDateTime parameter type
  """

  use Parameter.Parametrizable

  @doc """
  loads NaiveDateTime type

  ## Examples
      iex> Parameter.Types.NaiveDateTime.load(~N[2000-01-01 23:00:07])
      {:ok, ~N[2000-01-01 23:00:07]}

      iex> Parameter.Types.NaiveDateTime.load("2000-01-01 22:00:07")
      {:ok, ~N[2000-01-01 22:00:07]}

      iex> Parameter.Types.NaiveDateTime.load({{2021, 05, 11}, {22, 30, 10}})
      {:ok, ~N[2021-05-11 22:30:10]}

      iex> Parameter.Types.NaiveDateTime.load({{2021, 25, 11}, {22, 30, 10}})
      {:error, "invalid naive_datetime type"}

      iex> Parameter.Types.NaiveDateTime.load("2015-25-23")
      {:error, "invalid naive_datetime type"}
  """
  @impl true
  def load(%NaiveDateTime{} = value) do
    {:ok, value}
  end

  def load({{_year, _month, _day}, {_hour, _min, _sec}} = value) do
    case NaiveDateTime.from_erl(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(value) when is_binary(value) do
    case NaiveDateTime.from_iso8601(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(_value) do
    error_tuple()
  end

  @impl true
  def validate(%NaiveDateTime{}) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid naive_datetime type"}
end
