defmodule Parameter.Field do
  @moduledoc """
  This module define the structure of a Field inside a Parameter Schema.
  """

  alias Parameter.Types

  defstruct [:name, :key, :default, type: :string, required: false, validator: nil]

  @type t :: %__MODULE__{
          name: atom(),
          key: binary(),
          default: any(),
          type: Types.t(),
          required: boolean(),
          validator: fun()
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

  defp do_new(opts) do
    key = Keyword.fetch!(opts, :key)
    type = Keyword.get(opts, :type, :string)
    default = Keyword.get(opts, :default)
    required = Keyword.get(opts, :required, false)
    validator = Keyword.get(opts, :validator)

    default_valid? =
      if default do
        Types.validate(type, default)
      else
        :ok
      end

    type_valid? = type_valid?(type)
    validator_valid? = validator_valid?(validator)

    # Using Types module to validate field parameters
    with :ok <- default_valid?,
         :ok <- type_valid?,
         :ok <- Types.validate(:string, key),
         :ok <- Types.validate(:boolean, required),
         :ok <- validator_valid? do
      struct!(__MODULE__, opts)
    end
  end

  defp type_valid?({type, _inner_type}) do
    if type in Types.composite_types() do
      :ok
    else
      custom_type_valid?(type)
    end
  end

  defp type_valid?(type) do
    if type in Types.base_types() do
      :ok
    else
      custom_type_valid?(type)
    end
  end

  defp custom_type_valid?(custom_type) do
    if Kernel.function_exported?(custom_type, :load, 1) and
         Kernel.function_exported?(custom_type, :validate, 1) and
         Kernel.function_exported?(custom_type, :dump, 1) do
      :ok
    else
      {:error,
       "#{inspect(custom_type)} is not a valid custom type, implement the `Parameter.Parametrizable` on custom modules"}
    end
  end

  defp validator_valid?(validator)
       when is_function(validator, 1) or is_nil(validator) or is_tuple(validator) do
    :ok
  end

  defp validator_valid?(_validator) do
    {:error, "validator must be a function"}
  end
end
