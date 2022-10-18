defmodule Parameter.ValidatorsTest do
  use ExUnit.Case

  alias Parameter.Validators

  test "email/1" do
    assert Validators.email("user@gmail.com") == :ok
    assert Validators.email("otherUser@hotmail.com") == :ok
    assert Validators.email("other.value@outlook.com") == :ok
    assert Validators.email("") == {:error, "is invalid"}
    assert Validators.email("@") == {:error, "is invalid"}
    assert Validators.email("user@user") == {:error, "is invalid"}
  end

  test "equal/2" do
    assert Validators.equal("value", "value") == :ok
    assert Validators.equal(25, 25) == :ok
    assert Validators.equal(25, "value") == {:error, "is invalid"}
    assert Validators.equal(25, 15) == {:error, "is invalid"}
  end

  test "length/3" do
    assert Validators.length(15, 12, 16) == :ok
    assert Validators.length("value", "sm", "value_bigger") == :ok
    assert Validators.length(25, 12, 16) == {:error, "is invalid"}
    assert Validators.length(5, 6, 12) == {:error, "is invalid"}
    assert Validators.length("value", "value_big", "value_bigger") == {:error, "is invalid"}
  end

  test "one_of/2" do
    assert Validators.one_of(15, [15, 5]) == :ok
    assert Validators.one_of(5, [15, 5]) == :ok
    assert Validators.one_of(2, [15, 5]) == {:error, "is invalid"}
    assert Validators.one_of("value", ["value", "otherValue"]) == :ok
    assert Validators.one_of("otherValue", ["value", "otherValue"]) == :ok
    assert Validators.one_of("notIncluded", ["value", "otherValue"]) == {:error, "is invalid"}
  end

  test "none_of/2" do
    assert Validators.none_of(15, [15, 5]) == {:error, "is invalid"}
    assert Validators.none_of(5, [15, 5]) == {:error, "is invalid"}
    assert Validators.none_of(2, [15, 5]) == :ok
    assert Validators.none_of("value", ["value", "otherValue"]) == {:error, "is invalid"}
    assert Validators.none_of("otherValue", ["value", "otherValue"]) == {:error, "is invalid"}
    assert Validators.none_of("notIncluded", ["value", "otherValue"]) == :ok
  end

  test "regex/2" do
    assert Validators.regex("foo", ~r/foo/) == :ok
    assert Validators.regex("foobar", ~r/foo/) == :ok
    assert Validators.regex("bar", ~r/foo/) == {:error, "is invalid"}
  end
end
