defmodule Parameter.Types.Boolean do
  @moduledoc """
  Boolean parameter type
  """

  use Parameter.Parametrizable

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

  @impl true
  def validate(value) when is_boolean(value) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid boolean type"}
end
