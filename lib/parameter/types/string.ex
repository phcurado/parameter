defmodule Parameter.Types.String do
  @moduledoc """
  String parameter type
  """

  use Parameter.Parametrizable

  @impl true
  def load(value) do
    {:ok, to_string(value)}
  end

  @impl true
  def validate(value) when is_binary(value) do
    :ok
  end

  def validate(_value) do
    {:error, "invalid string type"}
  end
end
