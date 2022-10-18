defmodule Parameter.Schema.CompilerTest do
  use ExUnit.Case

  alias Parameter.Schema.Compiler

  test "don't compile options for nested fields" do
    assert_raise ArgumentError, "default cannot be used on nested field", fn ->
      Compiler.fetch_nested_opts!(default: nil)
    end

    assert_raise ArgumentError, "validator cannot be used on nested field", fn ->
      Compiler.fetch_nested_opts!(validator: nil)
    end

    assert [other_opts: nil] == Compiler.fetch_nested_opts!(other_opts: nil)
  end
end
