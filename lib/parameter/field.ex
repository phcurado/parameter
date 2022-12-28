defmodule Parameter.Field do
  @moduledoc """
  The field inside a Parameter Schema have the following structure:
      field :name, :type, opts

  * `:name` - Atom key that defines the field name
  * `:type` - Type from `Parameter.Types`. For custom types check the `Parameter.Parametrizable` behaviour.
  * `:opts` - Keyword with field options.

  ## Options
  * `:key` - This is the key from the params that will be converted to the field schema. Examples:
    * If an input field use `camelCase` for mapping `first_name`, this option should be set as "firstName".
    * If an input field use the same case for the field definition, this key can be ignored.

  * `:default` - Default value of the field when no value is given.

  * `:load_default` - Default value of the field when no value is given when loading with `Parameter.load/3` function.
  This option should not be used at the same time as `default` option.

  * `:dump_default` - Default value of the field when no value is given when loading with `Parameter.dump/3` function.
  This option should not be used at the same time as `default` option.

  * `:required` - Defines if the field needs to be present when parsing the input.
  `Parameter.load/3` will return an error if the value is missing from the input data.

  * `:validator` - Validation function that will validate the field after loading.

  * `:virtual` - If `true` the field will be ignored on `Parameter.load/3` and `Parameter.dump/3` functions.

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
    :load,
    :load_default,
    :dump_default,
    :validator,
    type: :string,
    required: false,
    virtual: false
  ]

  @type t :: %__MODULE__{
          name: atom(),
          key: binary(),
          default: any(),
          load: fun() | nil,
          load_default: any(),
          dump_default: any(),
          type: Types.t(),
          required: boolean(),
          validator: fun() | nil,
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
    load_default = Keyword.get(opts, :load_default)
    dump_default = Keyword.get(opts, :dump_default)
    required = Keyword.get(opts, :required, false)
    validator = Keyword.get(opts, :validator)
    load = Keyword.get(opts, :load)
    virtual = Keyword.get(opts, :virtual, false)

    # Using Types module to validate field parameters
    with {:ok, opts} <- default_valid?(type, opts, default, load_default, dump_default),
         :ok <- Types.validate(:string, key),
         :ok <- Types.validate(:boolean, required),
         :ok <- Types.validate(:boolean, virtual),
         :ok <- validator_valid?(validator),
         :ok <- load_or_dump_is_valid?(load) do
      struct!(__MODULE__, opts)
    end
  end

  defp default_valid?(type, opts, default, nil, nil) when not is_nil(default) do
    case validate_default(type, default) do
      :ok ->
        opts =
          opts
          |> Keyword.put(:load_default, default)
          |> Keyword.put(:dump_default, default)

        {:ok, opts}

      error ->
        error
    end
  end

  defp default_valid?(type, opts, nil, load_default, dump_default) do
    with :ok <- validate_default(type, load_default),
         :ok <- validate_default(type, dump_default),
         do: {:ok, opts}
  end

  defp default_valid?(_type, _opts, _default, _load_default, _dump_default) do
    {:error, "`default` opts should not be used with `load_default` or `dump_default`"}
  end

  defp validate_default(type, default_value) do
    if default_value do
      Types.validate(type, default_value)
    else
      :ok
    end
  end

  defp load_or_dump_is_valid?(load_or_dump)
       when is_function(load_or_dump, 1) or is_nil(load_or_dump) do
    :ok
  end

  defp load_or_dump_is_valid?(_load_or_dump) do
    # {:error, "Must be a function"}
    :ok
  end

  defp validator_valid?(validator)
       when is_function(validator, 1) or is_nil(validator) or is_tuple(validator) do
    :ok
  end

  defp validator_valid?(_validator) do
    {:error, "validator must be a function"}
  end
end
