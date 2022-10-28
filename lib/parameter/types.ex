defmodule Parameter.Types do
  @moduledoc """
  Parameter supports different types to be used in the field inside a schema. The available types are:

  - `string`
  - `atom`
  - `any`
  - `integer`
  - `float`
  - `boolean`
  - `map`
  - `array`
  - `date`
  - `time`
  - `datetime`
  - `naive_datetime`
  - `decimal`*
  - `enum`**


  \\* For decimal type add the [decimal](https://hexdocs.pm/decimal) library into your project.

  \\*\\* Check the `Parameter.Enum` for more information on how to use enums.

  For implementing custom types check the `Parameter.Parametrizable` module. Implementing this behavour in a module makes eligible to be a field in the schema definition.
  """
  @type t :: base_types | composite_types

  @type base_types ::
          :string
          | :atom
          | :any
          | :boolean
          | :date
          | :datetime
          | :decimal
          | :float
          | :integer
          | :list
          | :map
          | :naive_datetime
          | :string
          | :time

  @type composite_types :: {:has_many, t()} | {:has_one, t()}

  @base_types ~w(atom any boolean date datetime decimal float integer list map naive_datetime string time)a
  @composite_types ~w(has_one has_many)a

  @spec base_types() :: [atom()]
  def base_types, do: @base_types

  @spec composite_types() :: [atom()]
  def composite_types, do: @composite_types

  @types_mod %{
    any: Parameter.Types.Any,
    atom: Parameter.Types.Atom,
    boolean: Parameter.Types.Boolean,
    date: Parameter.Types.Date,
    datetime: Parameter.Types.DateTime,
    decimal: Parameter.Types.Decimal,
    float: Parameter.Types.Float,
    integer: Parameter.Types.Integer,
    list: Parameter.Types.List,
    map: Parameter.Types.Map,
    naive_datetime: Parameter.Types.NaiveDateTime,
    string: Parameter.Types.String,
    time: Parameter.Types.Time
  }

  @spec load(atom(), any()) :: {:ok, any()} | {:error, any()}
  def load(type, value) do
    type_module = Map.get(@types_mod, type, type)
    type_module.load(value)
  end

  @spec dump(atom(), any()) :: {:ok, any()} | {:error, any()}
  def dump(type, value) do
    type_module = Map.get(@types_mod, type, type)
    type_module.dump(value)
  end

  @spec validate!(atom(), any()) :: :ok | no_return()
  def validate!(type, value) do
    case validate(type, value) do
      {:error, error} -> raise ArgumentError, message: error
      result -> result
    end
  end

  @spec validate(atom(), any()) :: :ok | {:error, any()}
  def validate(type, values)

  def validate({:has_one, inner_type}, values) when is_map(values) do
    Enum.reduce_while(values, :ok, fn {_key, value}, acc ->
      case validate(inner_type, value) do
        :ok -> {:cont, acc}
        error -> {:halt, error}
      end
    end)
  end

  def validate({:has_one, _inner_type}, _values) do
    {:error, "invalid inner data type"}
  end

  def validate({:has_many, inner_type}, values) when is_list(values) do
    Enum.reduce_while(values, :ok, fn value, acc ->
      case validate(inner_type, value) do
        :ok -> {:cont, acc}
        error -> {:halt, error}
      end
    end)
  end

  def validate({:has_many, _inner_type}, _values) do
    {:error, "invalid list type"}
  end

  def validate(type, value) do
    type_module = Map.get(@types_mod, type, type)
    type_module.validate(value)
  end
end
