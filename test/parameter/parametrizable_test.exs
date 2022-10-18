defmodule Parameter.ParametrizableTest do
  use ExUnit.Case

  alias Parameter.Parametrizable

  defmodule Param do
    use Parametrizable
  end

  test "check default parameters of parametrizable" do
    assert Param.load("value") == {:ok, "value"}
    assert Param.validate("value") == :ok
    assert Param.dump("value") == {:ok, "value"}
  end
end
