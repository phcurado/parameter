defmodule Parameter.FieldTest do
  use ExUnit.Case

  alias Parameter.Field

  describe "new/1" do
    test "initializes a new field struct" do
      opts = [
        name: :main_address,
        type: :string,
        key: "mainAddress",
        required: true,
        default: "Default"
      ]

      assert %Parameter.Field{
               default: "Default",
               key: "mainAddress",
               name: :main_address,
               required: true,
               type: :string,
               load_default: "Default",
               dump_default: "Default"
             } == Field.new(opts)
    end

    test "fails if a default value of wrong type" do
      opts = [
        name: :main_address,
        type: :float,
        key: "mainAddress",
        required: true,
        default: "Hello"
      ]

      assert {:error, "invalid float type"} == Field.new(opts)
    end

    test "fails if name is not an atom" do
      opts = [
        name: "main_address",
        type: :float,
        key: "mainAddress",
        required: true,
        default: "Hello"
      ]

      assert {:error, "invalid atom type"} == Field.new(opts)
    end

    test "fails on invalid function" do
      opts = [
        name: :address,
        type: :float,
        on_load: fn val -> val end,
        key: "mainAddress",
        required: true
      ]

      assert {:error, "on_load must be a function with 2 arity"} == Field.new(opts)
    end

    test "fails if a default value used at the sametime with load_default and dump_default" do
      opts = [
        name: :main_address,
        type: :string,
        key: "mainAddress",
        required: true,
        default: "Hello",
        load_default: "Hello"
      ]

      assert {:error, "`default` opts should not be used with `load_default` or `dump_default`"} ==
               Field.new(opts)
    end
  end

  describe "new!/1" do
    test "initializes a new field struct" do
      opts = [
        name: :main_address,
        type: :string,
        key: "mainAddress",
        required: true,
        default: "Default"
      ]

      assert %Parameter.Field{
               default: "Default",
               key: "mainAddress",
               name: :main_address,
               required: true,
               type: :string,
               dump_default: "Default",
               load_default: "Default"
             } == Field.new!(opts)
    end

    test "fails if a default value of wrong type" do
      opts = [
        name: :address,
        type: :float,
        key: "address",
        required: true,
        default: "Hello"
      ]

      assert_raise ArgumentError, "invalid float type", fn ->
        Field.new!(opts)
      end
    end
  end
end
