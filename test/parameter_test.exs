defmodule ParameterTest do
  use ExUnit.Case

  defmodule AddressTestSchema do
    use Parameter.Schema

    param do
      param :city, :string, required: true
      param :street, :string
      param :number, :integer
    end
  end

  defmodule UserTestSchema do
    use Parameter.Schema

    param do
      param :first_name, :string, key: "firstName", required: true
      param :last_name, :string, key: "lastName", required: true, default: ""
      param :age, :integer
      param :main_address, {:map, AddressTestSchema}, key: "mainAddress", required: true
      param :other_addresses, {:array, AddressTestSchema}, key: "otherAddresses"
      param :numbers, {:array, :integer}
    end
  end

  describe "load/3" do
    test "load user schema with correct input on all fields" do
      params = %{
        "firstName" => "Paulo",
        "lastName" => "Curado",
        "age" => "32",
        "mainAddress" => %{"city" => "Some City", "street" => "Some street", "number" => "15"},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => 10}
        ],
        "numbers" => ["1", 2, 5, "10"]
      }

      assert %{
               first_name: "Paulo",
               last_name: "Curado",
               age: 32,
               main_address: %{city: "Some City", street: "Some street", number: 15},
               other_addresses: [
                 %{city: "Some City", street: "Some street", number: 15},
                 %{city: "Other city", street: "Other street", number: 10}
               ],
               numbers: [1, 2, 5, 10]
             } == Parameter.load(UserTestSchema, params)
    end

    test "load user schema with invalid input shoud return an error" do
      params = %{
        "firstName" => "Paulo",
        "lastName" => "Curado",
        "age" => "not a age number",
        "mainAddress" => %{
          "city" => "Some City",
          "street" => "Some street",
          "number" => "not a number"
        },
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => "not a number"}
        ],
        "numbers" => ["number", 2, 5, "10", "invalid data"]
      }

      assert {:error,
              %{
                age: "invalid integer type",
                main_address: %{number: "invalid integer type"},
                other_addresses: ["1": %{number: "invalid integer type"}],
                numbers: [
                  "0": "invalid integer type",
                  "4": "invalid integer type"
                ]
              }} ==
               Parameter.load(UserTestSchema, params)
    end

    test "load user schema with struct true" do
      params = %{
        "firstName" => "Paulo",
        "lastName" => "Curado",
        "age" => "32",
        "mainAddress" => %{"city" => "Some City", "street" => "Some street", "number" => "15"},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => 10}
        ],
        "numbers" => ["1", 2, 5, "10"]
      }

      assert %UserTestSchema{
               first_name: "Paulo",
               last_name: "Curado",
               age: 32,
               main_address: %AddressTestSchema{
                 city: "Some City",
                 street: "Some street",
                 number: 15
               },
               other_addresses: [
                 %AddressTestSchema{city: "Some City", street: "Some street", number: 15},
                 %AddressTestSchema{city: "Other city", street: "Other street", number: 10}
               ],
               numbers: [1, 2, 5, 10]
             } == Parameter.load(UserTestSchema, params, struct: true)
    end
  end
end
