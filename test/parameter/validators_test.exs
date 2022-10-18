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
    assert Validators.equal("value", to: "value") == :ok
    assert Validators.equal(25, to: 25) == :ok
    assert Validators.equal(25, to: "value") == {:error, "is invalid"}
    assert Validators.equal(25, to: 15) == {:error, "is invalid"}
  end

  test "length/3" do
    assert Validators.length(15, min: 12, max: 16) == :ok
    assert Validators.length("value", min: "sm", max: "value_bigger") == :ok
    assert Validators.length(25, min: 12, max: 16) == {:error, "is invalid"}
    assert Validators.length(5, min: 6, max: 12) == {:error, "is invalid"}

    assert Validators.length("value", min: "value_big", max: "value_bigger") ==
             {:error, "is invalid"}
  end

  test "one_of/2" do
    assert Validators.one_of(15, options: [15, 5]) == :ok
    assert Validators.one_of(5, options: [15, 5]) == :ok
    assert Validators.one_of(2, options: [15, 5]) == {:error, "is invalid"}
    assert Validators.one_of("value", options: ["value", "otherValue"]) == :ok
    assert Validators.one_of("otherValue", options: ["value", "otherValue"]) == :ok

    assert Validators.one_of("notIncluded", options: ["value", "otherValue"]) ==
             {:error, "is invalid"}
  end

  test "none_of/2" do
    assert Validators.none_of(15, options: [15, 5]) == {:error, "is invalid"}
    assert Validators.none_of(5, options: [15, 5]) == {:error, "is invalid"}
    assert Validators.none_of(2, options: [15, 5]) == :ok
    assert Validators.none_of("value", options: ["value", "otherValue"]) == {:error, "is invalid"}

    assert Validators.none_of("otherValue", options: ["value", "otherValue"]) ==
             {:error, "is invalid"}

    assert Validators.none_of("notIncluded", options: ["value", "otherValue"]) == :ok
  end

  test "regex/2" do
    assert Validators.regex("foo", regex: ~r/foo/) == :ok
    assert Validators.regex("foobar", regex: ~r/foo/) == :ok
    assert Validators.regex("bar", regex: ~r/foo/) == {:error, "is invalid"}
  end
end
