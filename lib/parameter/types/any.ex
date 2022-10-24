defmodule Parameter.Types.Any do
  @moduledoc """
  Any parameter type. It will accept any input value without validations.
  The same value loaded will be the same dumped.
  """

  @behaviour Parameter.Parametrizable

  @impl true
  def load(value), do: {:ok, value}

  @impl true
  def dump(value), do: {:ok, value}

  @impl true
  def validate(_value), do: :ok
end
