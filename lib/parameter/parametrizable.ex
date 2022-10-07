defmodule Parameter.Parametrizable do
  @moduledoc """
  Behavour for implementing new parameter types.
  """

  @callback load(any(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  @callback validate(any(), Keyword.t()) :: :ok | {:error, binary()}
end
