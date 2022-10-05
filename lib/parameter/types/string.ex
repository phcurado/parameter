defmodule Parameter.Types.String do
  @moduledoc """
  String parameter type
  """

  use Parameter.Types

  def load(value) do
    to_string(value)
  end

  def validate(value) when is_binary(value) do
    :ok
  end

  def validate(_value) do
    {:error, "invalid string type"}
  end
end
