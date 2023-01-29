defmodule Parameter.Types.AnyType do
  @moduledoc """
  Any parameter type. It will accept any input value without validations.
  The same value loaded will be the same dumped.
  """

  @behaviour Parameter.Parametrizable

  @doc """
  `Any` type will just return the same type value that is passed to load function

  ## Examples
      iex> Parameter.Types.AnyType.load(:any_atom)
      {:ok, :any_atom}

      iex> Parameter.Types.AnyType.load("some string")
      {:ok, "some string"}

      iex> Parameter.Types.AnyType.load(nil)
      {:ok, nil}
  """
  @impl true
  def load(value), do: {:ok, value}

  @doc """
  `AnyType` type will just return the same type value that is passed to dump function

  ## Examples
      iex> Parameter.Types.AnyType.load(:any_atom)
      {:ok, :any_atom}

      iex> Parameter.Types.AnyType.load("some string")
      {:ok, "some string"}

      iex> Parameter.Types.AnyType.load(nil)
      {:ok, nil}
  """
  @impl true
  def dump(value), do: {:ok, value}

  @doc """
  Always return `:ok`, any value is valid
  """
  @impl true
  def validate(_value), do: :ok
end
