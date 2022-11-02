defmodule Parameter.Types.Date do
  @moduledoc """
  Date parameter type
  """

  use Parameter.Parametrizable

  @doc """
  loads Date type

  ## Examples
      iex> Parameter.Types.Date.load(%Date{year: 1990, month: 5, day: 1})
      {:ok, ~D[1990-05-01]}

      iex> Parameter.Types.Date.load({2020, 10, 5})
      {:ok, ~D[2020-10-05]}

      iex> Parameter.Types.Date.load("2015-01-23")
      {:ok, ~D[2015-01-23]}

      iex> Parameter.Types.Date.load("2015-25-23")
      {:error, "invalid date type"}
  """
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

  @doc """
  validate date type

  ## Examples
      iex> Parameter.Types.Date.validate(%Date{year: 1990, month: 5, day: 1})
      :ok

      iex> Parameter.Types.Date.validate(~D[1990-05-01])
      :ok

      iex> Parameter.Types.Date.validate("2015-01-23")
      {:error, "invalid date type"}
  """
  @impl true
  def validate(%Date{}) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid date type"}
end
