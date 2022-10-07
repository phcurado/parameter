defmodule Parameter.Types.Time do
  @moduledoc """
  Time parameter type
  """

  @behaviour Parameter.Parametrizable

  @impl true
  def load(date, opts \\ [])

  def load(%Time{} = value, _opts) do
    {:ok, value}
  end

  def load({_hour, _min, _sec} = value, _opts) do
    case Time.from_erl(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(value, _opts) when is_binary(value) do
    case Time.from_iso8601(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date} -> {:ok, date}
    end
  end

  def load(_value, _opts) do
    error_tuple()
  end

  @impl true
  def validate(date, opts \\ [])

  def validate(%Time{}, _opts) do
    :ok
  end

  def validate(_value, _opts) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid time type"}
end
