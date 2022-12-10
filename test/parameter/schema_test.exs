defmodule Parameter.SchemaTest do
  use ExUnit.Case

  alias Parameter.Field
  alias Parameter.Schema

  describe "compile/1" do
    test "compile a schema" do
      schema = %{
        first_name: [key: "firstName", type: :string, required: true],
        address: [required: true, type: {:has_one, %{street: [type: :string, required: true]}}],
        phones: [type: {:has_many, %{country: [type: :string, required: true]}}]
      }

      expected_compiled_schema = [
        %Field{
          name: :first_name,
          key: "firstName",
          default: nil,
          load_default: nil,
          dump_default: nil,
          type: :string,
          required: true,
          validator: nil,
          virtual: false
        },
        %Field{
          name: :address,
          key: "address",
          default: nil,
          load_default: nil,
          dump_default: nil,
          type:
            {:has_one,
             [
               %Field{
                 name: :street,
                 key: "street",
                 default: nil,
                 load_default: nil,
                 dump_default: nil,
                 type: :string,
                 required: true,
                 validator: nil,
                 virtual: false
               }
             ]},
          required: true,
          validator: nil,
          virtual: false
        },
        %Field{
          name: :phones,
          key: "phones",
          default: nil,
          load_default: nil,
          dump_default: nil,
          type:
            {:has_many,
             [
               %Field{
                 name: :country,
                 key: "country",
                 default: nil,
                 load_default: nil,
                 dump_default: nil,
                 type: :string,
                 required: true,
                 validator: nil,
                 virtual: false
               }
             ]},
          required: false,
          validator: nil,
          virtual: false
        }
      ]

      compiled_schema = Schema.compile!(schema)

      assert from_name(compiled_schema, :first_name) ==
               from_name(expected_compiled_schema, :first_name)

      assert from_name(compiled_schema, :address) == from_name(expected_compiled_schema, :address)
      assert from_name(compiled_schema, :phones) == from_name(expected_compiled_schema, :phones)

      assert {:error, %{address: "is required"}} ==
               Parameter.load(compiled_schema, %{"firstName" => "John"})

      assert {:ok, %{first_name: "John", address: %{street: "some street"}}} ==
               Parameter.load(compiled_schema, %{
                 "firstName" => "John",
                 "address" => %{"street" => "some street"}
               })
    end

    test "schema with wrong values should return errors" do
      schema = %{
        first_name: [key: :first_name, type: :string, required: :atom],
        address: [required: true, type: {:not_nested, %{street: [type: :string, required: true]}}],
        phones: [type: {:has_many, %{country: [type: :string, virtual: :not_virtual]}}]
      }

      assert_raise ArgumentError, fn ->
        Schema.compile!(schema)
      end
    end
  end

  defp from_name(parameters, name) do
    Enum.find(parameters, &(&1.name == name))
  end
end
