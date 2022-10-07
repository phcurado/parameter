defmodule Parameter.Field do
  @moduledoc """
  This module define the structure of a Field inside a Parameter Schema.
  """

  alias Parameter.Types

  defstruct [:name, :key, :default, :opts, type: :string, required: false]

  @type t :: %__MODULE__{
          name: atom(),
          key: binary(),
          default: any(),
          type: Types.t(),
          required: boolean(),
          opts: Keyword.t()
        }

  @spec new!(Keyword.t()) :: t() | no_return()
  def new!(opts \\ []) do
    case new(opts) do
      {:error, error} -> raise ArgumentError, message: error
      %__MODULE__{} = result -> result
    end
  end

  @spec new(opts :: Keyword.t()) :: t() | {:error, binary()}
  def new(opts \\ []) do
    name = Keyword.get(opts, :name)

    case Types.validate(:atom, name) do
      :ok ->
        key = Keyword.get(opts, :key, to_string(name))

        opts
        |> Keyword.put(:key, key)
        |> do_new()

      error ->
        error
    end
  end

  @spec load(t(), any()) :: {:ok, any} | {:error, binary()}
  def load(%__MODULE__{type: type, opts: opts}, value) do
    Types.load(type, value, opts)
  end

  defp do_new(opts) do
    {key, updated_opts} = Keyword.pop!(opts, :key)
    {name, updated_opts} = Keyword.pop!(updated_opts, :name)
    {type, updated_opts} = Keyword.pop(updated_opts, :type, :string)
    {default, updated_opts} = Keyword.pop(updated_opts, :default)
    {required, updated_opts} = Keyword.pop(updated_opts, :required, false)

    default_valid? =
      if default do
        Types.validate(type, default)
      else
        :ok
      end

    type_valid? = type_valid?(type)

    # Using Types module to validate field parameters
    with :ok <- default_valid?,
         :ok <- type_valid?,
         :ok <- Types.validate(:string, key),
         :ok <- Types.validate(:boolean, required) do
      params = %{
        key: key,
        type: type,
        default: default,
        required: required,
        name: name,
        opts: updated_opts
      }

      struct!(__MODULE__, params)
    end
  end

  defp type_valid?({type, _inner_type}) do
    if type in Types.composite_types() do
      :ok
    else
      {:error, "#{inspect(type)} is not a valid type"}
    end
  end

  defp type_valid?(type) do
    if type in Types.base_types() do
      :ok
    else
      {:error, "#{inspect(type)} is not a valid type"}
    end
  end
end
