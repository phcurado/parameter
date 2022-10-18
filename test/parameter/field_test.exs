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
               type: :string
             } = Field.new(opts)
    end

    test "fails if a default value of wrong type" do
      opts = [
        name: :main_address,
        type: :float,
        key: "mainAddress",
        required: true,
        default: "Hello"
      ]

      assert {:error, "invalid float type"} = Field.new(opts)
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
               type: :string
             } = Field.new!(opts)
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
