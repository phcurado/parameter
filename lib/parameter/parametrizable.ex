defmodule Parameter.Parametrizable do
  @moduledoc """
  Custom types for fields can be done by implementing the `Parameter.Parametrizable` behaviour.
  This is useful when the basic types provided by `Parameter.Types` are not enough for loading, validating and dumping data.

  ## Example
  To create a parameterized type, create a module as shown below:
      defmodule MyApp.CustomType do
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
      param MyApp.CustomParam do
        field :custom_field, MyApp.CustomType, key: "customField"
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

      @impl true
      def load(value), do: {:ok, value}

      @impl true
      def dump(value) do
        case validate(value) do
          :ok -> {:ok, value}
          error -> error
        end
      end

      @impl true
      def validate(_value), do: :ok

      defoverridable(Parameter.Parametrizable)
    end
  end
end
