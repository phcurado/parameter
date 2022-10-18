defmodule Parameter.Parametrizable do
  @moduledoc """
  Custom types per fields to be implemented using `Parameter.Parametrizable` module.
  When the basic types are not enough for loading, validating and dumping data this
  module can be used to provide custom types.

  ## Example
  To create a parameterized type, create a module as shown below:
      defmodule CustomType do
        use Parameter.Parametrizable

        @impl true
        def load(value) do
          {:ok, value}
        end

        @impl true
        def validate(_value) do
          :ok
        end

        @impl true
        def dump(value) do
          {:ok, value}
        end
      end

  Then use the new custom type on a param schema:
      param CustomParam do
        field :custom_field, CustomType, key: "customField"
      end

  In general is not necessary to implement dump function since using the macro `use Parameter.Parametrizable`
  will already use the validate function to dump the value as a default implementation.
  """

  @callback load(any()) :: {:ok, any()} | {:error, any()}
  @callback dump(any()) :: {:ok, any()} | {:error, any()}
  @callback validate(any()) :: :ok | {:error, any()}

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour Parameter.Parametrizable

      def load(value), do: {:ok, value}

      def dump(value) do
        case validate(value) do
          :ok -> {:ok, value}
          error -> error
        end
      end

      def validate(value), do: :ok

      defoverridable(Parameter.Parametrizable)
    end
  end
end
