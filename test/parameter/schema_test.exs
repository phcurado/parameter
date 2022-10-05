defmodule Parameter.SchemaTest do
  use ExUnit.Case
  doctest Parameter.Schema

  alias Parameter.Schema
  alias Parameter.Field

  test "field schema with valid data" do
    assert Schema.new(:string) == %Field{key: ""}
  end

  test "field schema with invvalid data" do
    assert Schema.new(:invalid) == {:error, ":invalid is not a valid type"}
  end

  test "simple map schema with valid data" do
    schema = %{
      first_name: {:string, required: true, key: "firstName"},
      last_name: :string,
      age: :integer
    }

    assert Schema.new(schema) == %{
             first_name: %Field{name: :first_name, key: "firstName", required: true},
             last_name: %Field{name: :last_name, key: "last_name"},
             age: %Field{name: :age, type: :integer, key: "age"}
           }
  end

  test "simple map schema with invalid data" do
    schema = %{
      first_name: :not_string,
      last_name: :other_invalid_type,
      age: :integer
    }

    assert Schema.new(schema) ==
             {:error,
              %{
                first_name: ":not_string is not a valid type",
                last_name: ":other_invalid_type is not a valid type"
              }}
  end

  test "nested map schema with valid data" do
    schema = %{
      first_name: {:string, required: true, key: "firstName"},
      last_name: :string,
      age: :integer,
      address: %{
        street: :string
      }
    }

    assert Schema.new(schema) == %{
             first_name: %Field{name: :first_name, key: "firstName", required: true},
             last_name: %Field{name: :last_name, key: "last_name"},
             age: %Field{name: :age, type: :integer, key: "age"},
             address: %{
               street: %Field{name: :street, key: "street"}
             }
           }
  end
end
