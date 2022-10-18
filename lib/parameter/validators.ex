defmodule Parameter.Validators do
  @moduledoc """
  Common validators to use with the schema

  ## Example
      param User do
        field :email, :string, validator: &Validators.email(&1)
      end

      iex> Parameter.load(User, %{"email" => "not an email"})
      {:error, %{email: "is invalid"}}
  """

  @type resp :: :ok | {:error, binary()}
  @email_regex ~r/^[A-Za-z0-9\._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}$/

  @doc """
  Validates email address
      param User do
        field :email, :string, validator: &Validators.email(&1)
      end

      iex> Parameter.load(User, %{"email" => "not an email"})
      {:error, %{email: "is invalid"}}

      iex> Parameter.load(User, %{"email" => "john@gmail.com"})
      {:ok, %{email: "john@gmail.com"}}
  """
  @spec email(binary()) :: resp
  def email(value) when is_binary(value) do
    if String.match?(value, @email_regex) do
      :ok
    else
      error_tuple()
    end
  end

  @doc """
  Validates if value is equal to another
      param User do
        field :permission, :string, validator: {&Validators.equal/2, to: "admin"}
      end

      iex> Parameter.load(User, %{"permission" => "super_admin"})
      {:error, %{permission: "is invalid"}}

      iex> Parameter.load(User, %{"permission" => "admin"})
      {:ok, %{permission: "admin"}}
  """
  @spec equal(binary(), to: any()) :: resp
  def equal(value, to: comparable) do
    if value == comparable do
      :ok
    else
      error_tuple()
    end
  end

  @doc """
  Validates if a value is between a min and max
      param User do
        field :age, :integer, validator: {&Validators.length/2, min: 18, max: 50}
      end

      iex> Parameter.load(User, %{"age" => 12})
      {:error, %{age: "is invalid"}}

      iex> Parameter.load(User, %{"age" => 30})
      {:ok, %{age: 30}}
  """
  @spec length(binary(), min: any(), max: any()) :: resp
  def length(value, min: min, max: max) do
    if value >= min and value <= max do
      :ok
    else
      error_tuple()
    end
  end

  @doc """
  Validates if a value is a member of the list
      param User do
        field :permission, :atom, validator: {&Validators.one_of/2, options: [:admin, :super_admin]}
      end

      iex> Parameter.load(User, %{"permission" => "normal_user"})
      {:error, %{permission: "is invalid"}}

      iex> Parameter.load(User, %{"permission" => "super_admin"})
      {:ok, %{permission: :super_admin}}
  """
  @spec one_of(binary(), options: any()) :: resp
  def one_of(value, options: options) when is_list(options) do
    if value in options do
      :ok
    else
      error_tuple()
    end
  end

  @doc """
  Validates if a value is not a member
      param User do
        field :permission, :atom, validator: {&Validators.none_of/2, options: [:admin, :super_admin]}
      end

      iex> Parameter.load(User, %{"permission" => "super_admin"})
      {:error, %{permission: "is invalid"}}

      iex> Parameter.load(User, %{"permission" => "normal_user"})
      {:ok, %{permission: :normal_user}}
  """
  @spec none_of(binary(), options: any()) :: resp
  def none_of(value, options: options) do
    case one_of(value, options: options) do
      :ok -> error_tuple()
      _error -> :ok
    end
  end

  @doc """
  Validates if a value matches a regex expression
      param User do
        field :code, :string, validator: {&Validators.regex/2, regex: ~r/code/}
      end

      iex> Parameter.load(User, %{"code" => "12345"})
      {:error, %{code: "is invalid"}}

      iex> Parameter.load(User, %{"code" => "code:12345"})
      {:ok, %{code: "code:12345"}}
  """
  @spec regex(binary(), regex: any()) :: resp
  def regex(value, regex: regex) when is_binary(value) do
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
