defmodule Parameter.Field do
  @moduledoc """
  The field inside a Parameter Schema have the following structure:
      field :name, :type, opts

  * `:name` - Atom key that defines the field name
  * `:type` - Type from `Parameter.Types`. For custom types check the `Parameter.Parametrizable` behaviour.
  * `:opts` - Keyword with field options.

  ## Options
  * `:key` - This is the key from the params that will be converted to the field schema. As an example,
  when of the param comes with a camelCase for mapping `first_name`, this option should be set as "firstName".
  If this parameter is not set it will default to the field name.
  * `:default` - default value of the field when no value is given to the field.
  * `:required` - defines if the field needs to be present when parsing the input.
  `Parameter.load/3` will return an error if the value is missing from the input data.
  * `:validator` - Validation function that will validate the field after loading.
  * `:virtual` - if `true` the field will be ignored on `Parameter.load/2` and `Parameter.dump/2` functions.

  > NOTE: Validation only occurs on `Parameter.load/3`.
  > By desgin, data passed into `Parameter.dump/3` are considered valid.

  ## Example
  As an example having an `email` field that is required and needs email validation could be implemented this way:
      field :email, :string, required: true, validator: &Parameter.Validators.email/1
  """

  alias Parameter.Types

  defstruct [
    :name,
    :key,
    :default,
    type: :string,
    required: false,
    validator: nil,
    virtual: false
  ]

  @type t :: %__MODULE__{
          name: atom(),
          key: binary(),
          default: any(),
          type: Types.t(),
          required: boolean(),
          validator: fun(),
          virtual: boolean()
        }

  @doc false
  @spec new!(Keyword.t()) :: t() | no_return()
  def new!(opts \\ []) do
    case new(opts) do
      {:error, error} -> raise ArgumentError, message: error
      %__MODULE__{} = result -> result
    end
  end

  @doc false
  @spec new(opts :: Keyword.t()) :: t() | {:error, String.t()}
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
    virtual = Keyword.get(opts, :virtual, false)

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
         :ok <- Types.validate(:boolean, virtual),
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
