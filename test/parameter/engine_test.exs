defmodule Parameter.EngineTest do
  use ExUnit.Case

  alias Parameter.Engine
  alias Parameter.Schema
  alias Parameter.Factory.NestedSchema
  alias Parameter.Factory.SimpleSchema

  describe "cast/3" do
    import Parameter.Engine

    test "cast simple schema" do
      params = %{}
      field_names = Schema.field_names(SimpleSchema)
      fields = Schema.fields(SimpleSchema)

      assert %Engine{
               schema: SimpleSchema,
               cast_fields: field_names,
               changes: params,
               data: params,
               fields: fields
             } == cast(SimpleSchema, params)

      assert %Engine{
               schema: nil,
               cast_fields: field_names,
               changes: params,
               data: params,
               fields: fields
             } == cast(Schema.runtime_schema(SimpleSchema), params)
    end

    test "cast only a few fields" do
      params = %{}

      assert %Engine{cast_fields: [:first_name, :last_name]} =
               cast(SimpleSchema, params, only: [:first_name, :last_name])

      assert %Engine{cast_fields: [:age]} =
               cast(Schema.runtime_schema(SimpleSchema), params, only: [:age])

      assert %Engine{cast_fields: []} =
               cast(Schema.runtime_schema(SimpleSchema), params, only: [:not_a_field])
    end

    test "cast nested schema" do
      params = %{}
      field_names = Schema.field_names(NestedSchema)
      fields = Schema.fields(NestedSchema)

      assert %Engine{
               schema: NestedSchema,
               cast_fields: field_names,
               changes: params,
               data: params,
               fields: fields
             } == cast(NestedSchema, params)

      assert %Engine{
               schema: nil,
               cast_fields: field_names,
               changes: params,
               data: params,
               fields: fields
             } == cast(Schema.runtime_schema(NestedSchema), params)
    end

    test "cast only a few nested fields" do
      params = %{}

      assert %Engine{cast_fields: [{:addresses, [:street, :state]}]} =
               cast(NestedSchema, params, only: [{:addresses, [:street, :state]}])

      assert %Engine{cast_fields: [{:phone, [:number]}]} =
               cast(Schema.runtime_schema(NestedSchema), params,
                 only: [{:phone, [:number, :not_a_field]}]
               )
    end
  end
end
