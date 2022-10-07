defmodule Parameter.Types.String do
  @moduledoc """
  String parameter type
  """

  @behaviour Parameter.Parametrizable

  @impl true
  def load(date, opts \\ [])

  def load(value, _opts) do
    to_string(value)
  end

  @impl true
  def validate(date, opts \\ [])

  def validate(value, _opts) when is_binary(value) do
    :ok
  end

  def validate(_value, _opts) do
    {:error, "invalid string type"}
  end
end
