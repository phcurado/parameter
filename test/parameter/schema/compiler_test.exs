defmodule Parameter.Schema.CompilerTest do
  use ExUnit.Case

  alias Parameter.Schema.Compiler

  test "don't compile options for nested fields" do
    assert_raise ArgumentError, "default cannot be used on nested fields", fn ->
      Compiler.fetch_nested_opts!(default: nil)
    end

    assert_raise ArgumentError, "load_default cannot be used on nested fields", fn ->
      Compiler.fetch_nested_opts!(load_default: nil)
    end

    assert_raise ArgumentError, "dump_default cannot be used on nested fields", fn ->
      Compiler.fetch_nested_opts!(dump_default: nil)
    end

    assert_raise ArgumentError, "load_func cannot be used on nested fields", fn ->
      Compiler.fetch_nested_opts!(load_func: nil)
    end

    assert_raise ArgumentError, "dump_func cannot be used on nested fields", fn ->
      Compiler.fetch_nested_opts!(dump_func: nil)
    end

    assert_raise ArgumentError, "validator cannot be used on nested fields", fn ->
      Compiler.fetch_nested_opts!(validator: nil)
    end

    assert [other_opts: nil] == Compiler.fetch_nested_opts!(other_opts: nil)
  end
end
