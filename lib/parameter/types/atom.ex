defmodule Parameter.Types.Atom do
  @moduledoc """
  Atom parameter type
  """

  @behaviour Parameter.Parametrizable

  @impl true
  def load(value, opts \\ [])

  def load(nil, _opt), do: error_tuple()

  def load(value, _opts) when is_atom(value) do
    {:ok, value}
  end

  def load(value, opts) when is_binary(value) do
    only_existing_atoms? = Keyword.get(opts, :only_exisiting_atoms, true)

    if only_existing_atoms? do
      {:ok, String.to_existing_atom(value)}
    else
      {:ok, String.to_atom(value)}
    end
  rescue
    _error ->
      error_tuple()
  end

  def load(_value, _opts) do
    error_tuple()
  end

  @impl true
  def validate(value, opts \\ [])

  def validate(nil, _opts), do: error_tuple()

  def validate(value, _opts) when is_atom(value) do
    :ok
  end

  def validate(_value, _opts) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid atom type"}
end
