if Code.ensure_loaded?(Decimal) do
  defmodule Parameter.Types.Decimal do
    @moduledoc """
    Decimal parameter type.
    Include the Decimal library on your application to use this type:
        def deps do
          [
            {:parameter, "~> 0.4.0"},
            {:decimal, "~> 2.0"}
          ]
        end
    """

    use Parameter.Parametrizable

    @impl true
    def load(value) do
      case Decimal.cast(value) do
        :error -> error_tuple()
        {:ok, decimal} -> {:ok, decimal}
      end
    end

    @impl true
    def validate(%Decimal{}) do
      :ok
    end

    def validate(_value) do
      error_tuple()
    end

    defp error_tuple, do: {:error, "invalid decimal type"}
  end
end
