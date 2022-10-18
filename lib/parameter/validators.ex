defmodule Parameter.Validators do
  @moduledoc """
  Common validators to use with the schema

  ## Example
      param User do
        field :email, :string, validator: &Validators.email(&1)
      end

      iex> Parameter.load(User, %{"email" => "not an email"})
      {:error, email: "is invalid"}
  """
  @email_regex ~r/^[A-Za-z0-9\._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}$/

  @doc """
  Validates email address
  """
  def email(value) when is_binary(value) do
    if String.match?(value, @email_regex) do
      :ok
    else
      error_tuple()
    end
  end

  @doc """
  Validates if value is equal to another
  """
  def equal(value, comparable) do
    if value == comparable do
      :ok
    else
      error_tuple()
    end
  end

  @doc """
  Validates if a value is between a min and max
  """
  def length(value, min, max) do
    if value >= min and value <= max do
      :ok
    else
      error_tuple()
    end
  end

  @doc """
  Validates if a value is a member of the list
  """
  def one_of(value, list) do
    if value in list do
      :ok
    else
      error_tuple()
    end
  end

  @doc """
  Validates if a value is not a member
  """
  def none_of(value, list) do
    case one_of(value, list) do
      :ok -> error_tuple()
      _error -> :ok
    end
  end

  @doc """
  Validates if a value matches a regex expression
  """
  def regex(value, regex) when is_binary(value) do
    if String.match?(value, regex) do
      :ok
    else
      error_tuple()
    end
  end

  defp error_tuple do
    {:error, "is invalid"}
  end
end
