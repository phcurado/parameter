defmodule Parameter.Types.Atom do
  @moduledoc """
  Atom parameter type
  """

  use Parameter.Parametrizable

  @doc """
  loads atom type

  ## Examples
      iex> Parameter.Types.Atom.load(:atom)
      {:ok, :atom}

      iex> Parameter.Types.Atom.load("atom")
      {:ok, :atom}

      iex> Parameter.Types.Atom.load(nil)
      {:error, "invalid atom type"}

      iex> Parameter.Types.Atom.load(123)
      {:error, "invalid atom type"}
  """
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

  @doc """
  validate atom type

  ## Examples
      iex> Parameter.Types.Atom.validate(:atom)
      :ok

      iex> Parameter.Types.Atom.validate("atom")
      {:error, "invalid atom type"}

      iex> Parameter.Types.Atom.validate(nil)
      {:error, "invalid atom type"}

      iex> Parameter.Types.Atom.validate(123)
      {:error, "invalid atom type"}
  """
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
