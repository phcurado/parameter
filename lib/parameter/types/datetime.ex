defmodule Parameter.Types.DateTime do
  @moduledoc """
  DateTime parameter type
  """

  use Parameter.Parametrizable

  @doc """
  loads DateTime type

  ## Examples
      iex> Parameter.Types.DateTime.load(~U[2018-11-15 10:00:00Z])
      {:ok, ~U[2018-11-15 10:00:00Z]}

      iex> Parameter.Types.DateTime.load("2015-01-23T23:50:07Z")
      {:ok, ~U[2015-01-23 23:50:07Z]}

      iex> Parameter.Types.DateTime.load("2015-25-23")
      {:error, "invalid datetime type"}
  """
  @impl true
  def load(%DateTime{} = value) do
    {:ok, value}
  end

  def load(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:error, _reason} -> error_tuple()
      {:ok, date, _offset} -> {:ok, date}
    end
  end

  def load(_value) do
    error_tuple()
  end

  @doc """
  validate date type

  ## Examples
      iex> Parameter.Types.DateTime.validate(~U[2018-11-15 10:00:00Z])
      :ok

      iex> Parameter.Types.DateTime.validate(~D[1990-05-01])
      {:error, "invalid datetime type"}

      iex> Parameter.Types.DateTime.validate("2015-01-23T23:50:07Z")
      {:error, "invalid datetime type"}
  """
  @impl true
  def validate(%DateTime{} = _datetime) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid datetime type"}
end
