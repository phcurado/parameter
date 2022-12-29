defmodule Parameter.Meta do
  @moduledoc false

  alias Parameter.Field

  @type t :: %__MODULE__{
          schema: module() | list(Field.t()),
          input: map() | list(map()),
          parent_input: map() | list(map()),
          operation: :load | :dump | :validate
        }

  defstruct [
    :schema,
    :input,
    :parent_input,
    :operation
  ]

  def new(schema, input, params \\ []) do
    {_val, params} = Keyword.pop(params, :schema)
    {_val, params} = Keyword.pop(params, :input)
    {parent_input, params} = Keyword.pop(params, :parent_input)

    initial_params = [schema: schema, input: input, parent_input: parent_input || input]
    params = Keyword.merge(initial_params, params)

    struct!(__MODULE__, params)
  end

  def set_input(%__MODULE__{} = resolver, value) do
    set_field(resolver, :input, value)
  end

  def set_parent_input(%__MODULE__{} = resolver, value) do
    set_field(resolver, :parent_input, value)
  end

  def set_schema(%__MODULE__{} = resolver, value) do
    set_field(resolver, :schema, value)
  end

  def set_field(%__MODULE__{} = resolver, field, value) do
    Map.put(resolver, field, value)
  end
end
