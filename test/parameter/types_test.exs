defmodule Parameter.TypesTest do
  use ExUnit.Case

  alias Parameter.Types

  describe "load/2" do
    test "load string type" do
      assert Types.load(:string, "Test") == {:ok, "Test"}
      assert Types.load(:string, 1) == {:ok, "1"}
      assert Types.load(:string, true) == {:ok, "true"}
      assert Types.load(:string, "true") == {:ok, "true"}
    end

    test "load atom type" do
      assert Types.load(:atom, :test) == {:ok, :test}
      assert Types.load(:atom, 1) == {:error, "invalid atom type"}
      assert Types.load(:atom, true) == {:ok, true}
      assert Types.load(:atom, :SomeValue) == {:ok, :SomeValue}
      assert Types.load(:atom, "string type") == {:ok, :"string type"}
      assert Types.load(:atom, nil) == {:error, "invalid atom type"}

      assert Types.load(:atom, "hello mew") ==
               {:error, "invalid atom type"}

      assert Types.load(:atom, "hello_goodbuy", only_existing_atoms: false) ==
               {:ok, :hello_goodbuy}
    end

    test "load boolean type" do
      assert Types.load(:boolean, true) == {:ok, true}
      assert Types.load(:boolean, false) == {:ok, false}
      assert Types.load(:boolean, "True") == {:ok, true}
      assert Types.load(:boolean, "FalsE") == {:ok, false}
      assert Types.load(:boolean, 1) == {:ok, true}
      assert Types.load(:boolean, 0) == {:ok, false}
      assert Types.load(:boolean, "other value") == {:error, "invalid boolean type"}
    end

    test "load integer type" do
      assert Types.load(:integer, 1) == {:ok, 1}
      assert Types.load(:integer, "1") == {:ok, 1}
      assert Types.load(:integer, "other value") == {:error, "invalid integer type"}
      assert Types.load(:integer, 1.5) == {:error, "invalid integer type"}
    end

    test "load float type" do
      assert Types.load(:float, 1.5) == {:ok, 1.5}
      assert Types.load(:float, "1.2") == {:ok, 1.2}
      assert Types.load(:float, "other value") == {:error, "invalid float type"}
      assert Types.load(:float, 1) == {:ok, 1.0}
      assert Types.load(:float, "1") == {:ok, 1.0}
    end

    test "load date types" do
      assert Types.load(:date, %Date{year: 2020, month: 10, day: 5}) == {:ok, ~D[2020-10-05]}
      assert Types.load(:date, {2020, 11, 2}) == {:ok, ~D[2020-11-02]}
      assert Types.load(:date, ~D[2000-01-01]) == {:ok, ~D[2000-01-01]}
      assert Types.load(:date, "2000-01-01") == {:ok, ~D[2000-01-01]}
      assert Types.load(:date, "some value") == {:error, "invalid date type"}

      {:ok, time} = Time.new(0, 0, 0, 0)
      assert Types.load(:time, time) == {:ok, ~T[00:00:00.000000]}
      assert Types.load(:time, ~T[00:00:00.000000]) == {:ok, ~T[00:00:00.000000]}
      assert Types.load(:time, {22, 30, 10}) == {:ok, ~T[22:30:10]}
      assert Types.load(:time, "23:50:07") == {:ok, ~T[23:50:07]}
      assert Types.load(:time, ~D[2000-01-01]) == {:error, "invalid time type"}
      assert Types.load(:time, "some value") == {:error, "invalid time type"}

      assert Types.load(:datetime, ~U[2018-11-15 10:00:00Z]) == {:ok, ~U[2018-11-15 10:00:00Z]}
      assert Types.load(:datetime, ~D[2000-01-01]) == {:error, "invalid datetime type"}
      assert Types.load(:datetime, "some value") == {:error, "invalid datetime type"}

      naive_now = NaiveDateTime.local_now()
      assert Types.load(:naive_datetime, naive_now) == {:ok, naive_now}

      assert Types.load(:naive_datetime, ~N[2000-01-01 23:00:07]) ==
               {:ok, ~N[2000-01-01 23:00:07]}

      assert Types.load(:naive_datetime, {{2021, 05, 11}, {22, 30, 10}}) ==
               {:ok, ~N[2021-05-11 22:30:10]}

      assert Types.load(:naive_datetime, ~D[2000-01-01]) ==
               {:error, "invalid naive_datetime type"}

      assert Types.load(:naive_datetime, "some value") == {:error, "invalid naive_datetime type"}
    end

    test "return error when invalid type" do
      assert Types.load(:decimal, 1.5) == {:error, ":decimal is not a valid type"}

      assert Types.load("random type", 1.5) ==
               {:error, "\"random type\" is not a valid type"}
    end
  end

  describe "validate/2" do
    test "validate string type" do
      assert Types.validate(:string, "Test") == :ok
      assert Types.validate(:string, 1) == {:error, "invalid string type"}
      assert Types.validate(:string, true) == {:error, "invalid string type"}
      assert Types.validate(:string, "true") == :ok
    end

    test "validate atom type" do
      assert Types.validate(:atom, :test) == :ok
      assert Types.validate(:atom, 1) == {:error, "invalid atom type"}
      assert Types.validate(:atom, true) == :ok
      assert Types.validate(:atom, :SomeValue) == :ok
      assert Types.validate(:atom, nil) == {:error, "invalid atom type"}
    end

    test "validate boolean type" do
      assert Types.validate(:boolean, true) == :ok
      assert Types.validate(:boolean, "true") == {:error, "invalid boolean type"}
      assert Types.validate(:boolean, 2.5) == {:error, "invalid boolean type"}
    end

    test "validate integer type" do
      assert Types.validate(:integer, 1) == :ok
      assert Types.validate(:integer, "1") == {:error, "invalid integer type"}
      assert Types.validate(:integer, 1.5) == {:error, "invalid integer type"}
    end

    test "validate float type" do
      assert Types.validate(:float, 1.5) == :ok
      assert Types.validate(:float, 1) == {:error, "invalid float type"}
    end

    test "validate date types" do
      assert Types.validate(:date, %Date{year: 2020, month: 10, day: 5}) == :ok
      assert Types.validate(:date, ~D[2000-01-01]) == :ok
      assert Types.validate(:date, "2000-01-01") == {:error, "invalid date type"}

      {:ok, time} = Time.new(0, 0, 0, 0)
      assert Types.validate(:time, time) == :ok
      assert Types.validate(:time, ~D[2000-01-01]) == {:error, "invalid time type"}

      assert Types.validate(:datetime, ~U[2018-11-15 10:00:00Z]) == :ok
      assert Types.validate(:datetime, ~D[2000-01-01]) == {:error, "invalid datetime type"}

      assert Types.validate(:naive_datetime, NaiveDateTime.local_now()) == :ok
      assert Types.validate(:naive_datetime, ~N[2000-01-01 23:00:07]) == :ok

      assert Types.validate(:naive_datetime, ~D[2000-01-01]) ==
               {:error, "invalid naive_datetime type"}
    end

    test "return error when invalid type" do
      assert Types.validate(:decimal, 1.5) == {:error, ":decimal is not a valid type"}

      assert Types.validate("random type", 1.5) ==
               {:error, "\"random type\" is not a valid type"}
    end

    test "validate array with inner type" do
      assert Types.validate({:array, :string}, []) == :ok
      assert Types.validate({:array, :string}, ["hello", "world"]) == :ok

      assert Types.validate({:array, :string}, ["hello", :world]) ==
               {:error, "invalid string type"}

      assert Types.validate({:array, :string}, 3) == {:error, "not an array type"}
    end

    test "validate map with inner type" do
      assert Types.validate({:map, :string}, %{}) == :ok
      assert Types.validate({:map, :string}, %{key: "value", other_key: "other value"}) == :ok

      assert Types.validate({:map, :string}, %{key: "value", other_key: 22}) ==
               {:error, "invalid string type"}

      assert Types.validate({:map, :float}, "21") == {:error, "not a map type"}
    end
  end
end
