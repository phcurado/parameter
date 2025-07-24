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

  * `:on_load` - Function to specify how to load the field. The function must have two arguments where the first one is the field value and the second one
  will be the data to be loaded. Should return `{:ok, value}` or `{:error, reason}` tuple.

  * `:on_dump` - Function to specify how to dump the field. The function must have two arguments where the first one is the field value and the second one
  will be the data to be dumped. Should return `{:ok, value}` or `{:error, reason}` tuple.

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
    :on_load,
    :on_dump,
    default: :ignore,
    load_default: :ignore,
    dump_default: :ignore,
    type: :string,
    required: false,
    validator: nil,
    virtual: false
  ]

  @type validator_type ::
          (any(), any() -> :ok | {:error, any()})
          | (any() -> :ok | {:error, any()})
          | {(any(), list() -> :ok | {:error, any()}), list()}
          | {(any(), any(), list() -> :ok | {:error, any()}), list()}
          | nil

  @type t :: %__MODULE__{
          name: atom(),
          key: binary(),
          default: any(),
          load_default: any(),
          dump_default: any(),
          on_load: (any(), any() -> {:ok, any()} | {:error, any()}) | nil,
          on_dump: (any(), any() -> {:ok, any()} | {:error, any()}) | nil,
          type: Types.t(),
          required: boolean(),
          validator: validator_type(),
          virtual: boolean()
        }

  @doc false
  @spec new!(Keyword.t()) :: t() | no_return()
  def new!(opts) do
    case new(opts) do
      {:error, error} -> raise ArgumentError, message: error
      %__MODULE__{} = result -> result
    end
  end

  @doc false
  @spec new(opts :: Keyword.t()) :: t() | {:error, String.t()}
  def new(opts) do
    name = Keyword.get(opts, :name)
    type = Keyword.get(opts, :type)

    if name != nil and type != nil do
      do_new(opts)
    else
      {:error, "a field should have at least a name and a type"}
    end
  end

  defp do_new(opts) do
    name = Keyword.fetch!(opts, :name)
    default = Keyword.get(opts, :default, :ignore)
    load_default = Keyword.get(opts, :load_default, :ignore)
    dump_default = Keyword.get(opts, :dump_default, :ignore)
    on_load = Keyword.get(opts, :on_load)
    on_dump = Keyword.get(opts, :on_dump)
    required = Keyword.get(opts, :required, false)
    validator = Keyword.get(opts, :validator)
    virtual = Keyword.get(opts, :virtual, false)

    # Using Types module to validate field parameters
    with {:ok, opts} <- name_valid?(name, opts),
         key = Keyword.fetch!(opts, :key),
         {:ok, opts} <- fetch_default(opts, default, load_default, dump_default),
         :ok <- Types.validate(:string, key),
         :ok <- Types.validate(:boolean, required),
         :ok <- Types.validate(:boolean, virtual),
         :ok <- on_load_valid?(on_load),
         :ok <- on_dump_valid?(on_dump),
         :ok <- validator_valid?(validator) do
      struct!(__MODULE__, opts)
    end
  end

  defp name_valid?(name, opts) do
    case Types.validate(:atom, name) do
      :ok ->
        key = Keyword.get(opts, :key, to_string(name))

        {:ok, Keyword.put(opts, :key, key)}

      error ->
        error
    end
  end

  defp fetch_default(opts, default, :ignore, :ignore) when default != :ignore do
    opts =
      opts
      |> Keyword.put(:load_default, default)
      |> Keyword.put(:dump_default, default)

    {:ok, opts}
  end

  defp fetch_default(opts, :ignore, _load_default, _dump_default) do
    {:ok, opts}
  end

  defp fetch_default(_opts, _default, _load_default, _dump_default) do
    {:error, "`default` opts should not be used with `load_default` or `dump_default`"}
  end

  defp on_load_valid?(on_load) when is_function(on_load, 2) or is_nil(on_load),
    do: :ok

  defp on_load_valid?(_on_load) do
    {:error, "on_load must be a function with 2 arity"}
  end

  defp on_dump_valid?(on_dump) when is_function(on_dump, 2) or is_nil(on_dump),
    do: :ok

  defp on_dump_valid?(_on_dump) do
    {:error, "on_dump must be a function with 2 arity"}
  end

  defp validator_valid?({validator, args})
       when is_list(args) and (is_function(validator, 2) or is_function(validator, 3)),
       do: :ok

  defp validator_valid?(validator)
       when is_function(validator, 1) or is_function(validator, 2) or is_nil(validator),
       do: :ok

  defp validator_valid?(_validator),
    do:
      {:error,
       "validator must be a function with arity 1 or 2, or a tuple with a function and arguments"}
end
