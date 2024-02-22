defmodule Parameter.SchemaTest do
  use ExUnit.Case

  alias Parameter.Field
  alias Parameter.Schema

  describe "compile/1" do
    test "compile a schema" do
      schema = %{
        first_name: [key: "firstName", type: :string, required: true],
        address: [required: true, type: {:map, %{street: [type: :string, required: true]}}],
        phones: [type: {:array, %{country: [type: :string, required: true]}}]
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
            {:map,
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
            {:array,
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
        phones: [type: {:array, %{country: [type: :string, virtual: :not_virtual]}}]
      }

      assert_raise ArgumentError, fn ->
        Schema.compile!(schema)
      end
    end
  end

  describe "fields/1" do
    import Parameter.Schema

    param ModuleSchema do
      field :first_name, :string, required: true
    end

    test "module schema schema fields" do
      assert [%Parameter.Field{}] = Schema.fields(__MODULE__.ModuleSchema)
    end

    test "module schema has validate/1 and validate/2" do
      assert {:ok, %{first_name: "aaron"}} ==
               __MODULE__.ModuleSchema.validate(%{"first_name" => "aaron"}, [])

      assert {:error, %{first_name: "is required"}} == __MODULE__.ModuleSchema.validate(%{})
    end

    test "module schema has load/1 and load/2" do
      assert {:ok, %__MODULE__.ModuleSchema{first_name: "aaron"}} ==
               __MODULE__.ModuleSchema.load(%{"first_name" => "aaron"}, struct: true)

      assert {:error, %{first_name: "is required"}} == __MODULE__.ModuleSchema.load(%{})
    end

    test "module schema has dump/2" do
      assert {:ok, %{"first_name" => "aaron"}} ==
               __MODULE__.ModuleSchema.dump(%{first_name: "aaron"}, [])
    end

    test "runtime schema fields" do
      schema =
        %{
          first_name: [key: "firstName", type: :string, required: true],
          address: [required: true, type: {:map, %{street: [type: :string, required: true]}}],
          phones: [type: {:array, %{country: [type: :string, required: true]}}]
        }
        |> Schema.compile!()

      assert [%Parameter.Field{}, %Parameter.Field{}, %Parameter.Field{}] = Schema.fields(schema)
    end
  end

  defp from_name(parameters, name) do
    Enum.find(parameters, &(&1.name == name))
  end
end
