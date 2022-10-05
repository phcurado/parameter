defmodule Parameter.Types.Atom do
  @moduledoc """
  Atom parameter type
  """

  use Parameter.Types

  def load(value) when is_atom(value) do
    value
  end

  def load(value) when is_binary(value) do
    String.to_existing_atom(value)
  rescue
    _error ->
      String.to_atom(value)
  end

  def load(_value) do
    error_tuple()
  end

  def validate(value) when is_atom(value) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid atom type"}
end
