defmodule Parameter.ExcludeFieldsTest do
  use ExUnit.Case

  alias Parameter.ExcludeFields

  describe "field_to_exclude/2" do
    test "map if field should be excluded" do
      assert :include == ExcludeFields.field_to_exclude(:first_name, [])
      assert :include == ExcludeFields.field_to_exclude(:main_address, [:field])
      assert :exclude == ExcludeFields.field_to_exclude(:main_address, [:main_address])

      assert :exclude ==
               ExcludeFields.field_to_exclude(:main_address, [:field, :main_address, :field])

      assert :exclude ==
               ExcludeFields.field_to_exclude(:main_address, [
                 :field,
                 :main_address,
                 :field,
                 :main_address
               ])
    end

    test "map nested field to be excluded" do
      assert :include ==
               ExcludeFields.field_to_exclude(:first_name, [{:main_address, [:first_name]}])

      assert {:exclude, [:street]} ==
               ExcludeFields.field_to_exclude(:main_address, [{:main_address, [:street]}])

      assert {:exclude, [{:street, [:number]}]} ==
               ExcludeFields.field_to_exclude(:main_address, [
                 {:main_address, [{:street, [:number]}]}
               ])
    end

    test "sending wrong input should be ignored" do
      assert :include == ExcludeFields.field_to_exclude(:first_name, :first_name)
      assert :include == ExcludeFields.field_to_exclude(:first_name, [{:first_name}])
    end
  end
end
