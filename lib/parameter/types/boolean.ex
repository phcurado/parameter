defmodule Parameter.Types.Boolean do
  @moduledoc """
  Boolean parameter type
  """

  @behaviour Parameter.Parametrizable

  @impl true
  def load(value, _opts) when is_boolean(value) do
    value
  end

  def load(value, _opts) when is_binary(value) do
    case String.downcase(value) do
      "true" ->
        true

      "false" ->
        false

      _not_boolean ->
        error_tuple()
    end
  end

  def load(1, _opts) do
    true
  end

  def load(0, _opts) do
    false
  end

  def load(_value, _opts) do
    error_tuple()
  end

  @impl true
  def validate(value, _opts) when is_boolean(value) do
    :ok
  end

  def validate(_value, _opts) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid boolean type"}
end
