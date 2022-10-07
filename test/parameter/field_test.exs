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

    test "puts remaining opts into `opts` key" do
      opts = [
        name: :main_address,
        type: :string,
        key: "mainAddress",
        required: true,
        default: "Hello",
        values: [1, 5, 8],
        random_key: :hello
      ]

      assert %Parameter.Field{
               default: "Hello",
               key: "mainAddress",
               name: :main_address,
               opts: [values: [1, 5, 8], random_key: :hello],
               required: true,
               type: :string
             } = Field.new(opts)
    end
  end
end
