defmodule Parameter.Types.Date do
  @moduledoc """
  Date parameter type
  """

  @behaviour Parameter.Parametrizable

  @impl true
  def load(date, opts \\ [])

  def load(%Date{} = value, _opts) do
    {:ok, value}
  end

  def load({_year, _month, _day} = value, _opts) do
    case Date.from_erl(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(value, _opts) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(_value, _opts) do
    error_tuple()
  end

  @impl true
  def validate(date, opts \\ [])

  def validate(%Date{}, _opts) do
    :ok
  end

  def validate(_value, _opts) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid date type"}
end
