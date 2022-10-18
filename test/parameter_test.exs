defmodule ParameterTest do
  use ExUnit.Case

  defmodule CustomTypeHexToDecimal do
    use Parameter.Parametrizable

    @impl true
    def load(value)

    def load(value) when value in ["", nil], do: {:ok, nil}

    def load("0x0"), do: {:ok, 0}

    def load("0x" <> hex) do
      case Integer.parse(hex, 16) do
        {dec, ""} ->
          {:ok, dec}

        _ ->
          {:error, "invalid hex"}
      end
    end

    def load(_value) do
      {:error, "invalid hex"}
    end

    @impl true
    def dump(_value), do: {:ok, 0}

    @impl true
    def validate(value)

    def validate(value) when is_binary(value) do
      :ok
    end

    def validate(_value) do
      {:error, "not a string"}
    end
  end

  defmodule AddressTestSchema do
    use Parameter.Schema

    param do
      field :city, :string, required: true
      field :street, :string
      field :number, :integer
    end
  end

  defmodule UserTestSchema do
    use Parameter.Schema

    param do
      field :first_name, :string, key: "firstName", required: true
      field :last_name, :string, key: "lastName", required: true, default: ""
      field :age, :integer
      field :metadata, :map
      field :hex_amount, CustomTypeHexToDecimal, key: "hexAmount"
      has_one :main_address, AddressTestSchema, key: "mainAddress", required: true
      has_many :other_addresses, AddressTestSchema, key: "otherAddresses"
      has_many :numbers, :integer

      has_one :id_info, IdInfo, key: "idInfo" do
        field :number, :integer
        field :type, :string
      end

      has_many :info, Info do
        field :id, :string
      end
    end
  end

  defmodule Custom do
    import Parameter.Schema

    param User do
      field :first_name, :string, key: "firstName", required: true
      field :last_name, :string, key: "lastName", required: true

      has_many :phones, Phone, key: "phone", required: true do
        has_one :country, Country do
          field :code, :string
          field :name, :string
        end

        field :number, :integer, required: true
      end
    end
  end

  defmodule ValidatorSchema do
    use Parameter.Schema
    alias Parameter.Validators

    param do
      field :email, :string, validator: &Validators.email/1
      field :age, :integer, validator: {&Validators.length/2, min: 18, max: 72}
      field :code, :string, validator: {&Validators.regex/2, regex: ~r/code/}
      field :user_code, :string, validator: {&__MODULE__.is_equal/2, to: "0000"}

      field :permission, :atom,
        required: true,
        validator: {&Validators.one_of/2, options: [:admin, :normal]}

      has_many :nested, Nested, required: true do
        field :value, :string, validator: {&Validators.none_of/2, options: ["one", "two"]}
      end
    end

    def is_equal(value, to: to_value) do
      if value == to_value do
        :ok
      else
        {:error, "not equal"}
      end
    end
  end

  describe "load/3" do
    test "passing wrong opts raise RuntimeError" do
      assert_raise RuntimeError, fn ->
        Parameter.load(UserTestSchema, %{}, unknown: :unknown_opts)
      end
    end

    test "load user schema with correct input on all fields" do
      params = %{
        "firstName" => "John",
        "lastName" => "Doe",
        "age" => "32",
        "mainAddress" => %{"city" => "Some City", "street" => "Some street", "number" => "15"},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => 10}
        ],
        "numbers" => ["1", 2, 5, "10"],
        "metadata" => %{"key" => "value", "other_key" => "value"},
        "hexAmount" => "0x0",
        "idInfo" => %{
          "number" => 123_456,
          "type" => "identity"
        }
      }

      assert {:ok,
              %{
                first_name: "John",
                last_name: "Doe",
                age: 32,
                main_address: %{city: "Some City", street: "Some street", number: 15},
                other_addresses: [
                  %{city: "Some City", street: "Some street", number: 15},
                  %{city: "Other city", street: "Other street", number: 10}
                ],
                numbers: [1, 2, 5, 10],
                metadata: %{"key" => "value", "other_key" => "value"},
                hex_amount: 0,
                id_info: %{number: 123_456, type: "identity"}
              }} == Parameter.load(UserTestSchema, params)
    end

    test "load user schema with invalid input shoud return an error" do
      params = %{
        "firstName" => "John",
        "lastName" => "Doe",
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
        "numbers" => ["number", 2, 5, "10", "invalid data"],
        "metadata" => "not a map",
        "hexAmount" => 12,
        "idInfo" => %{
          "number" => "random",
          "type" => "identity"
        }
      }

      assert {:error,
              %{
                age: "invalid integer type",
                main_address: %{number: "invalid integer type"},
                other_addresses: ["1": %{number: "invalid integer type"}],
                numbers: [
                  "0": "invalid integer type",
                  "4": "invalid integer type"
                ],
                metadata: "invalid map type",
                hex_amount: "invalid hex",
                id_info: %{number: "invalid integer type"}
              }} ==
               Parameter.load(UserTestSchema, params)
    end

    test "load user schema with struct true" do
      params = %{
        "firstName" => "John",
        "lastName" => "Doe",
        "age" => "32",
        "mainAddress" => %{"city" => "Some City", "street" => "Some street", "number" => "15"},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => 10}
        ],
        "numbers" => ["1", 2, 5, "10"],
        "metadata" => %{"key" => "value", "other_key" => "value"},
        "hexAmount" => "0xbe807dddb074639cd9fa61b47676c064fc50d62c",
        "idInfo" => %{"number" => "25"},
        "info" => [%{"id" => "1"}]
      }

      assert {:ok,
              %UserTestSchema{
                first_name: "John",
                last_name: "Doe",
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
                numbers: [1, 2, 5, 10],
                metadata: %{"key" => "value", "other_key" => "value"},
                hex_amount: 1_087_573_706_314_634_443_003_985_449_474_964_098_995_406_820_908,
                id_info: %UserTestSchema.IdInfo{number: 25, type: nil},
                info: [%UserTestSchema.Info{id: "1"}]
              }} == Parameter.load(UserTestSchema, params, struct: true)
    end

    test "uses default value if value is nil" do
      params = %{
        "firstName" => "John",
        "lastName" => nil,
        "age" => "32",
        "mainAddress" => %{"city" => "Some City", "street" => "Some street", "number" => "15"},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => 10}
        ],
        "numbers" => ["1", 2, 5, "10"]
      }

      assert {:ok, %{last_name: ""}} = Parameter.load(UserTestSchema, params, struct: true)
    end

    test "fails a required value is not set" do
      params = %{
        "age" => "32",
        "mainAddress" => %{"city" => "Some City", "street" => "Some street", "number" => "15"},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => 10}
        ],
        "numbers" => ["1", 2, 5, "10"]
      }

      assert {:error, %{first_name: "is required"}} =
               Parameter.load(UserTestSchema, params, struct: true)
    end

    test "if unknown field set as error, it should fail when parsing unknown fields" do
      params = %{
        "firstName" => "John",
        "unknownField" => "some value",
        "age" => "32",
        "mainAddress" => %{"city" => "Some City", "street" => "Some street", "number" => "15"},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => 10}
        ],
        "otherInvalidField" => "invalid value",
        "numbers" => ["1", 2, 5, "10"]
      }

      assert {:error,
              %{"otherInvalidField" => "unknown field", "unknownField" => "unknown field"}} ==
               Parameter.load(UserTestSchema, params, unknown: :error)
    end

    test "if unknown field set as error, it should fail when parsing for nested data" do
      params = %{
        "firstName" => "John",
        "age" => "32",
        "mainAddress" => %{
          "city" => "Some City",
          "street" => "Some street",
          "number" => "15",
          "unknownField" => "some value"
        },
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{
            "city" => "Other city",
            "street" => "Other street",
            "number" => 10,
            "otherInvalidField" => "invalid value"
          }
        ],
        "numbers" => ["1", 2, 5, "10"]
      }

      assert {:error,
              %{
                main_address: %{"unknownField" => "unknown field"},
                other_addresses: ["1": %{"otherInvalidField" => "unknown field"}]
              }} ==
               Parameter.load(UserTestSchema, params, unknown: :error)
    end

    test "if unknown field set as exclude, it should ignore the unknown fields" do
      params = %{
        "firstName" => "John",
        "unknownField" => "some value",
        "age" => "32",
        "mainAddress" => %{"city" => "Some City", "street" => "Some street", "number" => "15"},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => 10}
        ],
        "otherInvalidField" => "invalid value",
        "numbers" => ["1", 2, 5, "10"]
      }

      assert {
               :ok,
               %{
                 first_name: "John",
                 age: 32,
                 last_name: "",
                 main_address: %{city: "Some City", number: 15, street: "Some street"},
                 numbers: [1, 2, 5, 10],
                 other_addresses: [
                   %{city: "Some City", number: 15, street: "Some street"},
                   %{city: "Other city", number: 10, street: "Other street"}
                 ]
               }
             } == Parameter.load(UserTestSchema, params, unknown: :ignore)
    end

    test "load custom module schema with param/2 macro" do
      params = %{
        "firstName" => "John",
        "lastName" => "Doe",
        "phone" => [
          %{
            "number" => "123456",
            "country" => %{
              "code" => "JP",
              "name" => "Japan"
            }
          },
          %{
            "number" => "222222",
            "country" => %{
              "code" => "BR",
              "name" => "Brazil"
            }
          }
        ]
      }

      assert {:ok,
              %{
                first_name: "John",
                last_name: "Doe",
                phones: [
                  %{country: %{code: "JP", name: "Japan"}, number: 123_456},
                  %{country: %{code: "BR", name: "Brazil"}, number: 222_222}
                ]
              }} == Parameter.load(Custom.User, params)
    end

    test "load custom module schema with param/2 macro  with struct true" do
      params = %{
        "firstName" => "John",
        "lastName" => "Doe",
        "phone" => [
          %{
            "number" => "123456",
            "country" => %{
              "code" => "JP",
              "name" => "Japan"
            }
          },
          %{
            "number" => "222222",
            "country" => %{
              "code" => "BR",
              "name" => "Brazil"
            }
          }
        ]
      }

      assert {
               :ok,
               %Custom.User{
                 first_name: "John",
                 last_name: "Doe",
                 phones: [
                   %Custom.User.Phone{
                     country: %Custom.User.Phone.Country{code: "JP", name: "Japan"},
                     number: 123_456
                   },
                   %Custom.User.Phone{
                     country: %Custom.User.Phone.Country{code: "BR", name: "Brazil"},
                     number: 222_222
                   }
                 ]
               }
             } == Parameter.load(Custom.User, params, struct: true)
    end

    test "load custom module with param/2 macro with invalid input shoud return an error" do
      params = %{
        "firstName" => "John",
        "phone" => [
          %{
            "number" => "asdf",
            "country" => %{
              "code" => "JP",
              "name" => "Japan"
            }
          },
          %{
            "number" => "asdf",
            "country" => %{
              "code" => "BR",
              "name" => "Brazil"
            }
          }
        ]
      }

      assert {:error,
              %{
                last_name: "is required",
                phones: [
                  {:"0", %{number: "invalid integer type"}},
                  {:"1", %{number: "invalid integer type"}}
                ]
              }} == Parameter.load(Custom.User, params)
    end

    test "load schema with right parameters on validation should load successfully" do
      params = %{
        "email" => "john@email.com",
        "age" => "22",
        "code" => "code:13234",
        "permission" => "admin",
        "user_code" => "0000",
        "nested" => [%{"value" => "three"}, %{"value" => "fourth"}]
      }

      assert {:ok,
              %{
                age: 22,
                code: "code:13234",
                email: "john@email.com",
                nested: [%{value: "three"}, %{value: "fourth"}],
                permission: :admin,
                user_code: "0000"
              }} == Parameter.load(ValidatorSchema, params)
    end

    test "load schema with wrong parameters on validation should fail" do
      params = %{
        "email" => "not email",
        "age" => "12",
        "code" => "asdf",
        "user_code" => "12345",
        "permission" => "super_admin",
        "nested" => [%{"value" => "one"}, %{"value" => "two"}, %{"wrong" => "wrong"}]
      }

      assert {:error,
              %{
                age: "is invalid",
                code: "is invalid",
                email: "is invalid",
                nested: [
                  {:"0", %{value: "is invalid"}},
                  {:"1", %{value: "is invalid"}},
                  {:"2", %{"wrong" => "unknown field"}}
                ],
                permission: "is invalid",
                user_code: "not equal"
              }} == Parameter.load(ValidatorSchema, params, unknown: :error)
    end
  end

  describe "dump/2" do
    test "dump schema input" do
      loaded_schema = %{
        first_name: "John",
        last_name: "Doe",
        age: 32,
        main_address: %{city: "Some City", street: "Some street", number: 15},
        other_addresses: [
          %{city: "Some City", street: "Some street", number: 15},
          %{city: "Other city", street: "Other street", number: 10}
        ],
        numbers: [1, 2, 5, 10],
        metadata: %{"key" => "value", "other_key" => "value"},
        hex_amount: "123123",
        id_info: %{number: 123, type: "identity"}
      }

      assert {:ok,
              %{
                "firstName" => "John",
                "lastName" => "Doe",
                "age" => 32,
                "mainAddress" => %{
                  "city" => "Some City",
                  "street" => "Some street",
                  "number" => 15
                },
                "otherAddresses" => [
                  %{"city" => "Some City", "street" => "Some street", "number" => 15},
                  %{"city" => "Other city", "street" => "Other street", "number" => 10}
                ],
                "numbers" => [1, 2, 5, 10],
                "metadata" => %{"key" => "value", "other_key" => "value"},
                "hexAmount" => 0,
                "idInfo" => %{
                  "number" => 123,
                  "type" => "identity"
                }
              }} == Parameter.dump(UserTestSchema, loaded_schema)
    end

    test "dump schema with invalid input should return error" do
      loaded_schema = %{
        last_name: 55,
        age: "not number",
        main_address: %{city: "Some City", street: "Some street", number: 15},
        other_addresses: [
          %{city: "Some City", street: 55, number: "Street"},
          %{city: "Other city", street: "Other street", number: 10}
        ],
        numbers: %{},
        metadata: [],
        hex_amount: :atom,
        id_info: %{number: 123, type: "identity"}
      }

      assert {
               :error,
               %{
                 age: "invalid integer type",
                 last_name: "invalid string type",
                 metadata: "invalid map type",
                 numbers: "invalid list type",
                 other_addresses: [
                   "0": %{number: "invalid integer type", street: "invalid string type"}
                 ]
               }
             } == Parameter.dump(UserTestSchema, loaded_schema)
    end
  end
end
