defmodule Parameter.Field do
  @moduledoc """
  This module define the structure of a Field inside a Parameter Schema.
  The field follow the structure:
      field :field_name, :field_type, opts

  The `:field_type` are types implemented on `Parameter.Types` or custom modules that implements the `Parameter.Parametrizable` behaviour.

  The other options available for the field are:
  - `key`: This is the key on the external source that will be converted to the param definition. As an example,
  when receiving data from an external source that uses a camelCase for mapping `first_name`, this option should be set as "firstName".
  If this parameter is not set it will default to the field name.
  - `default`: default value of the field when no value is given to the field.
  - `required`: defines if the field needs to be present when parsing the input.
  - `validator`: Validation function that will validate the field after loading.
  - `virtual`: if `true` the field will be ignored on `Parameter.load/2` and `Parameter.dump/2` functions.

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
