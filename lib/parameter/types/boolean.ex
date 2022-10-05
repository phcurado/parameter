defmodule Parameter.Types.Boolean do
  @moduledoc """
  Boolean parameter type
  """

  use Parameter.Types

  def load(value) when is_boolean(value) do
    value
  end

  def load(value) when is_binary(value) do
    case String.downcase(value) do
      "true" ->
        true

      "false" ->
        false

      _not_boolean ->
        error_tuple()
    end
  end

  def load(1) do
    true
  end

  def load(0) do
    false
  end

  def load(_value) do
    error_tuple()
  end

  def validate(value) when is_boolean(value) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid boolean type"}
end
