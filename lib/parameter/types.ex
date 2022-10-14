defmodule Parameter.Types do
  @moduledoc """
  Type behavour for implementing new types for parameters.
  """
  @type t :: base_types | composite_types

  @type base_types ::
          :string
          | :atom
          | :integer
          | :float
          | :boolean
          | :map
          | :date
          | :time
          | :datetime
          | :naive_datetime

  @type composite_types :: {:has_many, t()} | {:has_one, t()}

  @base_types ~w(string atom integer float boolean map date time datetime naive_datetime)a
  @composite_types ~w(has_one has_many)a

  @spec base_types() :: [atom()]
  def base_types, do: @base_types

  @spec composite_types() :: [atom()]
  def composite_types, do: @composite_types

  @types_mod %{
    atom: Parameter.Types.Atom,
    boolean: Parameter.Types.Boolean,
    datetime: Parameter.Types.DateTime,
    date: Parameter.Types.Date,
    float: Parameter.Types.Float,
    integer: Parameter.Types.Integer,
    naive_datetime: Parameter.Types.NaiveDateTime,
    string: Parameter.Types.String,
    time: Parameter.Types.Time,
    map: Parameter.Types.Map
  }

  @spec load(atom(), any()) :: {:ok, any()} | {:error, any()}
  def load(type, value) do
    type_module = Map.get(@types_mod, type) || type
    type_module.load(value)
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
    {:error, "not a inner type"}
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
    {:error, "not a list type"}
  end

  def validate(type, value) do
    case Map.get(@types_mod, type) do
      nil -> {:error, "#{inspect(type)} is not a valid type"}
      module -> module.validate(value)
    end
  end
end
