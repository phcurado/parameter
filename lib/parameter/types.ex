defmodule Parameter.Types do
  @moduledoc """
  Parameter supports different types to be used in the field inside a schema. The available types are:

  * `string`
  * `atom`
  * `any`
  * `integer`
  * `float`
  * `boolean`
  * `map`
  * `{map, nested_type}`
  * `array`
  * `{array, nested_type}`
  * `date`
  * `time`
  * `datetime`
  * `naive_datetime`
  * `decimal`*
  * `enum`**


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
          | :naive_datetime
          | :string
          | :time
          | :array
          | :map

  @type composite_types :: {:array, t()} | {:map, t()}

  @base_types ~w(atom any boolean date datetime decimal float integer naive_datetime string time)a
  @composite_types ~w(array map)a

  @spec base_type?(any) :: boolean
  def base_type?(type), do: type in @base_types

  @spec composite_inner_type?(any) :: boolean
  def composite_inner_type?({type, _}), do: type in @composite_types
  def composite_inner_type?(_), do: false

  @spec composite_type?(any) :: boolean
  def composite_type?({type, _}), do: type in @composite_types
  def composite_type?(type), do: type in @composite_types

  @types_mod %{
    any: Parameter.Types.Any,
    atom: Parameter.Types.Atom,
    boolean: Parameter.Types.Boolean,
    date: Parameter.Types.Date,
    datetime: Parameter.Types.DateTime,
    decimal: Parameter.Types.Decimal,
    float: Parameter.Types.Float,
    integer: Parameter.Types.Integer,
    array: Parameter.Types.Array,
    map: Parameter.Types.Map,
    naive_datetime: Parameter.Types.NaiveDateTime,
    string: Parameter.Types.String,
    time: Parameter.Types.Time
  }

  @spec load(atom(), any) :: {:ok, any()} | {:error, any()}
  def load(type, value) do
    type_module = Map.get(@types_mod, type, type)
    type_module.load(value)
  end

  @spec dump(atom(), any()) :: {:ok, any()} | {:error, any()}
  def dump(type, value) do
    type_module = Map.get(@types_mod, type, type)
    type_module.dump(value)
  end

  @spec validate!(t(), any()) :: :ok | no_return()
  def validate!(type, value) do
    case validate(type, value) do
      {:error, error} -> raise ArgumentError, message: error
      result -> result
    end
  end

  @spec validate(t(), any()) :: :ok | {:error, any()}
  def validate(type, values)

  def validate({:array, inner_type}, values) when is_list(values) do
    Enum.reduce_while(values, :ok, fn value, acc ->
      case validate(inner_type, value) do
        :ok -> {:cont, acc}
        error -> {:halt, error}
      end
    end)
  end

  def validate({:array, _inner_type}, _values) do
    {:error, "invalid array type"}
  end

  def validate({:map, inner_type}, values) when is_map(values) do
    Enum.reduce_while(values, :ok, fn {_key, value}, acc ->
      case validate(inner_type, value) do
        :ok -> {:cont, acc}
        error -> {:halt, error}
      end
    end)
  end

  def validate({:map, _inner_type}, _values) do
    {:error, "invalid map type"}
  end

  def validate(type, value) do
    type_module = Map.get(@types_mod, type, type)
    type_module.validate(value)
  end
end
