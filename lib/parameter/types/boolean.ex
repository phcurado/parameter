defmodule Parameter.Types.Boolean do
  @moduledoc """
  Boolean parameter type
  """

  use Parameter.Parametrizable

  @doc """
  loads boolean type

  ## Examples
      iex> Parameter.Types.Boolean.load("true")
      {:ok, true}

      iex> Parameter.Types.Boolean.load("false")
      {:ok, false}

      iex> Parameter.Types.Boolean.load(1)
      {:ok, true}

      iex> Parameter.Types.Boolean.load(0)
      {:ok, false}

      iex> Parameter.Types.Boolean.load("not boolean")
      {:error, "invalid boolean type"}
  """
  @impl true
  def load(value) when is_boolean(value) do
    {:ok, value}
  end

  def load(value) when is_binary(value) do
    case String.downcase(value) do
      "true" ->
        {:ok, true}

      "false" ->
        {:ok, false}

      "1" ->
        {:ok, true}

      "0" ->
        {:ok, false}

      _not_boolean ->
        error_tuple()
    end
  end

  def load(1) do
    {:ok, true}
  end

  def load(0) do
    {:ok, false}
  end

  def load(_value) do
    error_tuple()
  end

  @impl true
  def dump(value) when is_boolean(value) do
    {:ok, value}
  end

  def dump(_value) do
    error_tuple()
  end

  @doc """
  validate boolean type

  ## Examples
      iex> Parameter.Types.Boolean.validate(true)
      :ok

      iex> Parameter.Types.Boolean.validate(false)
      :ok

      iex> Parameter.Types.Boolean.validate("true")
      {:error, "invalid boolean type"}

      iex> Parameter.Types.Boolean.validate(nil)
      {:error, "invalid boolean type"}

      iex> Parameter.Types.Boolean.validate(123)
      {:error, "invalid boolean type"}
  """
  @impl true
  def validate(value) when is_boolean(value) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid boolean type"}
end
