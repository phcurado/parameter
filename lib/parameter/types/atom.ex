defmodule Parameter.Types.Atom do
  @moduledoc """
  Atom parameter type
  """

  @behaviour Parameter.Parametrizable

  @impl true
  def load(value, opts \\ [])

  def load(value, _opts) when is_atom(value) do
    value
  end

  def load(value, _opts) when is_binary(value) do
    String.to_existing_atom(value)
  rescue
    _error ->
      String.to_atom(value)
  end

  def load(_value, _opts) do
    error_tuple()
  end

  @impl true
  def validate(value, opts \\ [])

  def validate(value, _opts) when is_atom(value) do
    :ok
  end

  def validate(_value, _opts) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid atom type"}
end
