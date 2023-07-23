defmodule Parameter.EngineTest do
  use ExUnit.Case

  alias Parameter.Engine
  alias Parameter.Schema
  alias Parameter.Factory.NestedSchema
  alias Parameter.Factory.SimpleSchema

  describe "build/1" do
    test "build %Engine{} with runtime or compile time schemas" do
      field_names = Schema.field_names(SimpleSchema)
      fields = Schema.fields(SimpleSchema)

      assert %Engine{
               schema: SimpleSchema,
               cast_fields: field_names,
               fields: fields
             } == Engine.build(SimpleSchema)

      assert %Engine{
               schema: nil,
               cast_fields: field_names,
               fields: fields
             } == Engine.build(Schema.runtime_schema(SimpleSchema))
    end

    test "create engine with only a few fields" do
      engine = Engine.build(SimpleSchema)

      assert %Engine{cast_fields: [:first_name, :last_name]} =
               Engine.cast_only(engine, [:first_name, :last_name])

      assert %Engine{cast_fields: [:age]} = Engine.cast_only(engine, [:age])
      assert %Engine{cast_fields: []} = Engine.cast_only(engine, [:not_a_field])
    end
  end

  describe "load/3" do
    import Parameter.Engine

    test "load fields in a simple schema" do
      field_names = Schema.field_names(SimpleSchema)
      fields = Schema.fields(SimpleSchema)
      params = %{"firstName" => "John", "lastName" => "Doe", "age" => "40"}

      assert %Engine{
               schema: SimpleSchema,
               changes: %{first_name: "John", last_name: "Doe", age: 40},
               data: params,
               cast_fields: field_names,
               fields: fields,
               operation: :load
             } ==
               SimpleSchema
               |> build()
               |> load(params)
    end

    test "filtering fields on simple schema" do
      fields = Schema.fields(SimpleSchema)
      params = %{"firstName" => "John", "lastName" => "Doe", "age" => "40"}

      assert %Engine{
               schema: SimpleSchema,
               changes: %{first_name: "John", last_name: "Doe"},
               data: params,
               cast_fields: [:first_name, :last_name],
               fields: fields,
               operation: :load
             } ==
               SimpleSchema
               |> build()
               |> cast_only([:first_name, :last_name])
               |> load(params)
    end

    test "load fields in a nested schema" do
      field_names = Schema.field_names(NestedSchema)
      fields = Schema.fields(NestedSchema)

      params = %{
        "addresses" => [
          %{"street" => "some street", "number" => 4, "state" => "state"}
        ],
        "phone" => %{"code" => 1, "number" => "123123"}
      }

      assert %Engine{
               schema: NestedSchema,
               changes: %{
                 addresses: [
                   %Engine{
                     schema: NestedSchema.Address,
                     changes: %{street: "some street", number: 4, state: "state"},
                     data: %{"street" => "some street", "number" => 4, "state" => "state"},
                     cast_fields: [:state, :number, :street],
                     fields: Schema.fields(NestedSchema.Address),
                     operation: :load
                   }
                 ],
                 phone: %Engine{
                   schema: NestedSchema.Phone,
                   changes: %{code: "1", number: "123123"},
                   data: %{"code" => 1, "number" => "123123"},
                   cast_fields: [:code, :number],
                   fields: Schema.fields(NestedSchema.Phone),
                   operation: :load
                 }
               },
               data: params,
               cast_fields: field_names,
               fields: fields,
               operation: :load
             } ==
               NestedSchema
               |> build()
               |> load(params)
    end
  end
end
