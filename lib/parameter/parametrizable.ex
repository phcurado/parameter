defmodule Parameter.Parametrizable do
  @moduledoc """
  Behaviour for implementing new parameter types.
  """

  @callback load(any()) :: {:ok, any()} | {:error, any()}
  @callback validate(any()) :: :ok | {:error, binary()}
end
