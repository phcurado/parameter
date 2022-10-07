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
          | :array
          | :date
          | :time
          | :datetime
          | :naive_datetime

  @type composite_types :: {:array, t()} | {:map, t()}

  @base_types ~w(string atom integer float boolean map array date time datetime naive_datetime)a
  @composite_types ~w(map array)a

  def base_types, do: @base_types
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
    time: Parameter.Types.Time
  }

  @spec load(atom(), any(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def load(type, value, opts \\ []) do
    case Map.get(@types_mod, type) do
      nil -> {:error, "#{inspect(type)} is not a valid type"}
      module -> module.load(value, opts)
    end
  end

  @spec validate!(atom(), any(), Keyword.t()) :: :ok | no_return()
  def validate!(type, value, opts \\ []) do
    case validate(type, value, opts) do
      {:error, error} -> raise ArgumentError, message: error
      result -> result
    end
  end

  @spec load(atom(), any(), Keyword.t()) :: :ok | {:error, any()}
  def validate(type, values, opts \\ [])

  def validate({:map, inner_type}, values, opts) when is_map(values) do
    Enum.reduce_while(values, :ok, fn {_key, value}, acc ->
      case validate(inner_type, value, opts) do
        :ok -> {:cont, acc}
        error -> {:halt, error}
      end
    end)
  end

  def validate({:map, _inner_type}, _values, _opts) do
    {:error, "not a map type"}
  end

  def validate({:array, inner_type}, values, opts) when is_list(values) do
    Enum.reduce_while(values, :ok, fn value, acc ->
      case validate(inner_type, value, opts) do
        :ok -> {:cont, acc}
        error -> {:halt, error}
      end
    end)
  end

  def validate({:array, _inner_type}, _values, _opts) do
    {:error, "not an array type"}
  end

  def validate(type, value, opts) do
    case Map.get(@types_mod, type) do
      nil -> {:error, "#{inspect(type)} is not a valid type"}
      module -> module.validate(value, opts)
    end
  end
end
