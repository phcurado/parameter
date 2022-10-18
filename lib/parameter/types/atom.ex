defmodule Parameter.Types.Atom do
  @moduledoc """
  Atom parameter type
  """

  use Parameter.Parametrizable

  @impl true
  def load(nil), do: error_tuple()

  def load(value) when is_atom(value) do
    {:ok, value}
  end

  def load(value) when is_binary(value) do
    {:ok, String.to_atom(value)}
  end

  def load(_value) do
    error_tuple()
  end

  @impl true
  def validate(nil), do: error_tuple()

  def validate(value) when is_atom(value) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid atom type"}
end
