defmodule Parameter.Types do
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

  @callback load(any()) :: any()
  @callback dump(any()) :: any()
  @callback validate(any()) :: :ok | {:error, binary()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Parameter.Types

      def load(value), do: value
      def dump(value), do: value
      def validate(value), do: :ok

      defoverridable(Parameter.Types)
    end
  end

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

  def load(type, value) do
    case Map.get(@types_mod, type) do
      nil -> {:error, "#{inspect(type)} is not a valid type"}
      module -> module.load(value)
    end
  end

  def validate(type, value) do
    case Map.get(@types_mod, type) do
      nil -> {:error, "#{inspect(type)} is not a valid type"}
      module -> module.validate(value)
    end
  end

  # TODO validating composite types
  # defp validate({:array, inner_type}, values) when is_list(values) do
  #   Enum.reduce_while(values, :ok, fn value, acc ->
  #     case validate(inner_type, value) do
  #       :ok -> {:cont, acc}
  #       error -> {:halt, error}
  #     end
  #   end)
  # end

  # defp validate({:map, inner_type}, values) when is_map(values) do
  #   Enum.reduce_while(values, :ok, fn {_key, value}, acc ->
  #     case validate(inner_type, value) do
  #       :ok -> {:cont, acc}
  #       error -> {:halt, error}
  #     end
  #   end)
  # end
end
