defmodule Parameter.Types.DateTime do
  @moduledoc """
  DateTime parameter type
  """

  @behaviour Parameter.Parametrizable

  @impl true
  def load(date, opts \\ [])

  def load(%DateTime{} = value, _opts) do
    {:ok, value}
  end

  def load(value, _opts) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date, _offset} -> {:ok, date}
    end
  end

  def load(_value, _opts) do
    error_tuple()
  end

  @impl true
  def validate(date, opts \\ [])

  def validate(%DateTime{}, _opts) do
    :ok
  end

  def validate(_value, _opts) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid datetime type"}
end
