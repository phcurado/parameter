defmodule ParameterTest do
  use ExUnit.Case

  alias Parameter.Schema
  alias Parameter.Validators

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

    def validate(value) when is_binary(value) or is_integer(value) do
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
      field :street, :string, default: "Some street"
      field :number, :integer
    end
  end

  defmodule UserTestSchema do
    use Parameter.Schema

    enum Status do
      value :user_valid, key: "userValid"
      value :user_invalid, key: "userInvalid"
    end

    param do
      field :first_name, :string, key: "firstName", required: true
      field :last_name, :string, key: "lastName", required: true, default: ""
      field :age, :integer, on_load: &__MODULE__.load_age/2
      field :metadata, :map, dump_default: %{"key" => "value"}
      field :hex_amount, CustomTypeHexToDecimal, key: "hexAmount", default: "0"
      field :paid_amount, :decimal, key: "paidAmount", default: Decimal.new("1")
      field :status, __MODULE__.Status, required: true
      has_one :main_address, AddressTestSchema, key: "mainAddress", required: true
      has_many :other_addresses, AddressTestSchema, key: "otherAddresses"
      has_many :numbers, :integer, default: [1, 2]
      has_many :map_values, :map

      has_one :id_info, IdInfo, key: "idInfo" do
        field :number, :integer, load_default: 0, dump_default: 25
        field :type, :string

        field :age, :integer,
          on_load: &ParameterTest.UserTestSchema.load_info_age/2,
          on_dump: &ParameterTest.UserTestSchema.dump_age/2
      end

      has_many :info, Info do
        field :id, :string

        field :age, :string,
          on_load: &ParameterTest.UserTestSchema.load_info_age/2,
          on_dump: &ParameterTest.UserTestSchema.dump_info_age/2
      end
    end

    def load_age(value, input) do
      if age = input["idInfo"]["age"] do
        {:ok, age}
      else
        {:ok, value}
      end
    end

    def load_info_age(value, input) do
      if age = input["age"] || get_in(input, [:age]) do
        {:ok, age}
      else
        {:ok, value}
      end
    end

    def dump_info_age(value, input) do
      if age = input.age do
        {:ok, age}
      else
        {:ok, value}
      end
    end

    def dump_age(value, %UserTestSchema{} = input) do
      if value do
        {:ok, value}
      else
        {:ok, input.age}
      end
    end

    def dump_age(value, input) do
      if value do
        {:ok, value}
      else
        {:ok, get_in(input, [:age])}
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

    enum Status do
      value :user_valid, key: "userValid"
      value :user_invalid, key: "userInvalid"
    end

    param do
      field :email, :string, validator: &Validators.email/1
      field :age, :integer, validator: {&Validators.length/2, min: 18, max: 72}
      field :code, :string, validator: {&Validators.regex/2, regex: ~r/code/}
      field :user_code, :string, validator: {&__MODULE__.is_equal/2, to: "0000"}

      field :status, __MODULE__.Status,
        required: true,
        default: :user_valid,
        validator: {&Validators.one_of/2, options: [:user_valid]}

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

  defmodule VirtualFieldTestSchema do
    use Parameter.Schema
    alias Parameter.Validators

    param do
      field :email, :string, validator: &Validators.email/1
      field :password, :string, virtual: true

      has_many :addresses, Address do
        field :street, :string, virtual: true
        field :number, :integer
      end

      has_many :phones, Phone, virtual: true do
        field :number, :string
      end
    end
  end

  defmodule UserRequiredSchemaTest do
    use Parameter.Schema

    @fields_required true

    param do
      field :first_name, :string
      has_many :addresses, AddressTestSchema

      has_one :region, Region, required: false do
        field :place, :string
        field :street, :string, required: false
      end
    end
  end

  defmodule NestedSchemaTest do
    use Parameter.Schema

    param do
      field :nested_array, {:array, {:array, {:array, :float}}}
      field :nested_map, {:map, {:map, {:map, :integer}}}
    end
  end

  @attr_schema %{
                 user: [type: :string, required: true],
                 roles: [
                   type:
                     {:array,
                      %{
                        name: [
                          type: :integer,
                          required: true,
                          validator: {&Validators.one_of/2, options: [1, 2, 3]}
                        ],
                        permissions: [
                          type:
                            {:array,
                             %{
                               name: [
                                 type: :string,
                                 validator:
                                   {&Validators.one_of/2, options: ~w(create read update delete)}
                               ]
                             }}
                        ]
                      }}
                 ]
               }
               |> Schema.compile!()

  describe "load/3" do
    test "passing wrong opts raise RuntimeError" do
      assert_raise RuntimeError, fn ->
        Parameter.load(UserTestSchema, %{}, unknown: :unknown_opts)
      end
    end

    test "passing wrong value should return an error" do
      assert {:error, message} = Parameter.load(UserTestSchema, "not a map")
      assert message =~ "invalid input value %UndefinedFunctionError{"
    end

    test "validating required fields with nil and empty values" do
      assert {:error, %{city: "is required"}} == Parameter.load(AddressTestSchema, %{})

      assert {:error, %{city: "is required"}} ==
               Parameter.load(AddressTestSchema, %{city: nil, street: nil})

      assert {:ok, %{city: "", street: ""}} ==
               Parameter.load(AddressTestSchema, %{city: "", street: ""})

      assert {:ok, %{city: "Some city", street: ""}} ==
               Parameter.load(AddressTestSchema, %{city: "Some city", street: ""})

      assert {:ok, %{city: "Some city", street: nil}} ==
               Parameter.load(AddressTestSchema, %{city: "Some city", street: nil})

      assert {:ok, %{city: "Some city", street: "Some street"}} ==
               Parameter.load(AddressTestSchema, %{city: "Some city"})
    end

    test "validating required fields with nil and empty values with `ignore_nil` and `ignore_empty` options" do
      assert {:error, %{city: "is required"}} ==
               Parameter.load(AddressTestSchema, %{}, ignore_nil: true, ignore_empty: true)

      assert {:error, %{city: "is required"}} ==
               Parameter.load(AddressTestSchema, %{city: nil, street: nil},
                 ignore_nil: true,
                 ignore_empty: true
               )

      assert {:error, %{city: "is required"}} ==
               Parameter.load(AddressTestSchema, %{city: "", street: ""},
                 ignore_nil: true,
                 ignore_empty: true
               )

      assert {:ok, %{city: "Some city", street: "Some street"}} ==
               Parameter.load(AddressTestSchema, %{city: "Some city", street: ""},
                 ignore_nil: true,
                 ignore_empty: true
               )

      assert {:ok, %{city: "Some city", street: "Some street"}} ==
               Parameter.load(AddressTestSchema, %{city: "Some city", street: nil},
                 ignore_nil: true,
                 ignore_empty: true
               )
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
        "status" => "userValid",
        "paidAmount" => 25.00,
        "numbers" => ["1", 2, 5, "10"],
        "metadata" => %{"key" => "value", "other_key" => "value"},
        "map_values" => [%{"test" => "test"}],
        "hexAmount" => "0x0",
        "idInfo" => %{
          "number" => 123_456,
          "type" => "identity",
          "age" => "12"
        }
      }

      assert {:ok,
              %{
                first_name: "John",
                last_name: "Doe",
                age: 12,
                main_address: %{city: "Some City", street: "Some street", number: 15},
                other_addresses: [
                  %{city: "Some City", street: "Some street", number: 15},
                  %{city: "Other city", street: "Other street", number: 10}
                ],
                status: :user_valid,
                paid_amount: Decimal.new("25.0"),
                numbers: [1, 2, 5, 10],
                map_values: [%{"test" => "test"}],
                metadata: %{"key" => "value", "other_key" => "value"},
                hex_amount: 0,
                id_info: %{number: 123_456, type: "identity", age: 32}
              }} == Parameter.load(UserTestSchema, params)
    end

    test "load user schema with correct input on all fields and atom keys should work only if key equals the field name" do
      params = %{
        "firstName" => "John",
        "mainAddress" => %{city: "Some City", street: "Some street", number: "15"},
        lastName: "Doe",
        age: "32",
        otherAddresses: [
          %{city: "Some City", street: "Some street", number: 15},
          %{city: "Other city", street: "Other street", number: 10}
        ],
        status: "userValid",
        paidAmount: 25.00,
        numbers: ["1", 2, 5, "10"],
        metadata: %{"key" => "value", "other_key" => "value"},
        map_values: [%{"test" => "test"}],
        hexAmount: "0x0",
        id_info: %{
          number: 123_456,
          type: "identity"
        }
      }

      assert {:ok,
              %{
                first_name: "John",
                last_name: "",
                age: 32,
                main_address: %{city: "Some City", street: "Some street", number: 15},
                status: :user_valid,
                paid_amount: Decimal.new("1"),
                numbers: [1, 2, 5, 10],
                map_values: [%{"test" => "test"}],
                metadata: %{"key" => "value", "other_key" => "value"},
                hex_amount: "0",
                id_info: %{age: 32, number: 123_456, type: "identity"}
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
          %{"city" => "Some City", "street" => "Some street", "number" => 15, city: "city"},
          %{"city" => "Other city", "street" => "Other street", "number" => "not a number"}
        ],
        "status" => "anotherStatus",
        "numbers" => ["number", 2, 5, "10", "invalid data"],
        "metadata" => "not a map",
        "hexAmount" => 12,
        "idInfo" => %{
          "number" => "random",
          "type" => "identity",
          type: 12
        }
      }

      assert {:error,
              %{
                age: "invalid integer type",
                main_address: %{number: "invalid integer type"},
                other_addresses: %{
                  1 => %{number: "invalid integer type"},
                  0 => %{city: "field is present as atom and string keys"}
                },
                numbers: %{0 => "invalid integer type", 4 => "invalid integer type"},
                metadata: "invalid map type",
                hex_amount: "invalid hex",
                status: "invalid enum type",
                id_info: %{
                  number: "invalid integer type",
                  type: "field is present as atom and string keys",
                  age: "invalid integer type"
                }
              }} ==
               Parameter.load(UserTestSchema, params)
    end

    test "load user schema with invalid input type on nested paramaters shoud return an error" do
      params = %{
        "firstName" => "John",
        "lastName" => "Doe",
        "age" => 12,
        "mainAddress" => "not a map",
        "otherAddresses" => "not a list",
        "status" => "anotherStatus",
        "metadata" => "not a map",
        "hexAmount" => 12,
        "idInfo" => %{
          "number" => "random",
          "type" => "identity",
          type: 12
        }
      }

      assert {
               :error,
               %{
                 hex_amount: "invalid hex",
                 id_info: %{
                   number: "invalid integer type",
                   type: "field is present as atom and string keys"
                 },
                 main_address: "invalid map type",
                 metadata: "invalid map type",
                 other_addresses: "invalid array type",
                 status: "invalid enum type"
               }
             } == Parameter.load(UserTestSchema, params)
    end

    test "load user schema with ignore_nil true" do
      params = %{
        "firstName" => "John",
        "lastName" => "Doe",
        "age" => "32",
        "mainAddress" => %{"city" => "Some City", "street" => nil, "number" => nil},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => nil},
          %{"city" => "Other city", "street" => "Other street", "number" => 10}
        ],
        "status" => "userValid",
        "metadata" => %{"key" => "value", "other_key" => nil},
        "hexAmount" => nil,
        "idInfo" => %{"number" => "25"},
        "info" => [%{"id" => "1"}]
      }

      assert {:ok,
              %{
                first_name: "John",
                last_name: "Doe",
                age: 32,
                main_address: %{
                  city: "Some City",
                  street: "Some street"
                },
                other_addresses: [
                  %{city: "Some City", street: "Some street"},
                  %{city: "Other city", street: "Other street", number: 10}
                ],
                status: :user_valid,
                paid_amount: Decimal.new("1"),
                numbers: [1, 2],
                metadata: %{"key" => "value", "other_key" => nil},
                id_info: %{number: 25, age: 32},
                info: [%{id: "1", age: "32"}],
                hex_amount: "0"
              }} == Parameter.load(UserTestSchema, params, ignore_nil: true)
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
        "status" => "userValid",
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
                status: :user_valid,
                paid_amount: Decimal.new("1"),
                numbers: [1, 2],
                metadata: %{"key" => "value", "other_key" => "value"},
                hex_amount: 1_087_573_706_314_634_443_003_985_449_474_964_098_995_406_820_908,
                id_info: %UserTestSchema.IdInfo{number: 25, type: nil, age: 32},
                info: [%UserTestSchema.Info{id: "1", age: "32"}]
              }} == Parameter.load(UserTestSchema, params, struct: true)
    end

    test "don't use default value if value is nil" do
      params = %{
        "firstName" => "John",
        "lastName" => nil,
        "age" => "32",
        "mainAddress" => %{"city" => "Some City", "street" => "Some street", "number" => "15"},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => 10}
        ],
        "status" => "userValid",
        "numbers" => ["1", 2, 5, "10"]
      }

      assert {:ok, %{last_name: nil}} = Parameter.load(UserTestSchema, params, struct: true)
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
                other_addresses: %{1 => %{"otherInvalidField" => "unknown field"}},
                status: "is required"
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
        "status" => "userValid",
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
                 paid_amount: Decimal.new("1"),
                 status: :user_valid,
                 hex_amount: "0",
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
                phones: %{
                  0 => %{number: "invalid integer type"},
                  1 => %{number: "invalid integer type"}
                }
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
                user_code: "0000",
                status: :user_valid
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
                nested: %{
                  0 => %{value: "is invalid"},
                  1 => %{value: "is invalid"},
                  2 => %{"wrong" => "unknown field"}
                },
                permission: "is invalid",
                user_code: "not equal"
              }} == Parameter.load(ValidatorSchema, params, unknown: :error)
    end

    test "load user schema with excluded fields should ignore it" do
      params = %{
        "firstName" => "John",
        "lastName" => "Doe",
        "age" => "32",
        "mainAddress" => %{"street" => "Some street"},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => 10},
          %{"number" => 10}
        ],
        "status" => "userValid",
        "paidAmount" => 25.00,
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
                main_address: %{street: "Some street"},
                other_addresses: [
                  %{number: 15},
                  %{number: 10},
                  %{number: 10}
                ],
                paid_amount: Decimal.new("25.0"),
                numbers: [1, 2, 5, 10],
                hex_amount: 0,
                id_info: %{number: 123_456, age: 32}
              }} ==
               Parameter.load(UserTestSchema, params,
                 exclude: [
                   :status,
                   {:main_address, [:city, :number]},
                   {:other_addresses, [:street, :city]},
                   :metadata,
                   {:id_info, [:type]}
                 ]
               )
    end

    test "load user schema with struct true and excluded fields should set it to nil" do
      params = %{
        "firstName" => "John",
        "lastName" => "Doe",
        "age" => "32",
        "mainAddress" => %{"street" => "Some street"},
        "otherAddresses" => [
          %{"city" => "Some City", "street" => "Some street", "number" => 15},
          %{"city" => "Other city", "street" => "Other street", "number" => 10},
          %{"number" => 10}
        ],
        "status" => "userValid",
        "paidAmount" => 25.00,
        "numbers" => ["1", 2, 5, "10"],
        "metadata" => %{"key" => "value", "other_key" => "value"},
        "hexAmount" => "0x0",
        "idInfo" => %{
          "number" => 123_456,
          "type" => "identity"
        }
      }

      assert {:ok,
              %UserTestSchema{
                first_name: "John",
                last_name: "Doe",
                age: 32,
                main_address: %AddressTestSchema{street: "Some street", city: nil, number: nil},
                other_addresses: [
                  %AddressTestSchema{number: 15, city: nil, street: nil},
                  %AddressTestSchema{number: 10, city: nil, street: nil},
                  %AddressTestSchema{number: 10, city: nil, street: nil}
                ],
                paid_amount: Decimal.new("25.0"),
                numbers: [1, 2, 5, 10],
                hex_amount: 0,
                id_info: %UserTestSchema.IdInfo{number: 123_456, type: nil, age: 32},
                info: nil,
                metadata: nil,
                status: nil
              }} ==
               Parameter.load(UserTestSchema, params,
                 struct: true,
                 exclude: [
                   :status,
                   {:main_address, [:city, :number]},
                   {:other_addresses, [:street, :city]},
                   :metadata,
                   {:id_info, [:type]}
                 ]
               )
    end

    test "ignore virtual fields when loading" do
      params = %{
        "email" => "john@email.com",
        "password" => "123456",
        "addresses" => [
          %{"street" => "street", "number" => 12},
          %{"street" => "street_2", "number" => 15}
        ],
        "phones" => [
          %{"number" => "123456"},
          %{"number" => "654321"}
        ]
      }

      assert {:ok, %{email: "john@email.com", addresses: [%{number: 12}, %{number: 15}]}} ==
               Parameter.load(VirtualFieldTestSchema, params)

      assert {:ok, %{addresses: [%{number: 12}, %{number: 15}]}} ==
               Parameter.load(VirtualFieldTestSchema, params,
                 exclude: [:email, {:phones, [:number]}]
               )

      assert {:ok, %{addresses: [%{}, %{}]}} ==
               Parameter.load(VirtualFieldTestSchema, params,
                 exclude: [:email, {:addresses, [:number]}, {:phones, [:number]}]
               )
    end

    test "load input as a list with valid parameters" do
      params = [
        %{
          "firstName" => "John",
          "lastName" => "Doe",
          "age" => "32",
          "mainAddress" => %{"city" => "Some City", "street" => "Some street", "number" => "15"},
          "otherAddresses" => [
            %{"city" => "Some City", "street" => "Some street", "number" => 15},
            %{"city" => "Other city", "street" => "Other street", "number" => 10}
          ],
          "status" => "userValid",
          "paidAmount" => 25.00,
          "numbers" => ["1", 2, 5, "10"],
          "metadata" => %{"key" => "value", "other_key" => "value"},
          "hexAmount" => "0x0",
          "idInfo" => %{
            "number" => 123_456,
            "type" => "identity",
            "age" => "12"
          }
        },
        %{
          "firstName" => "Jane",
          "lastName" => "Doe",
          "age" => "32",
          "mainAddress" => %{"city" => "Jane City", "street" => "Jane street", "number" => "15"},
          "otherAddresses" => [
            %{"city" => "Jane City", "street" => "Jane street", "number" => 15},
            %{"city" => "Other city", "street" => "Other street", "number" => 10}
          ],
          "status" => "userInvalid",
          "paidAmount" => 25.00,
          "numbers" => ["1", 2, 5, "10"],
          "metadata" => %{"key" => "value", "other_key" => "value"},
          "hexAmount" => "0x0",
          "idInfo" => %{
            "number" => 123_456,
            "type" => "identity"
          }
        }
      ]

      assert {:ok,
              [
                %{
                  first_name: "John",
                  last_name: "Doe",
                  age: 12,
                  main_address: %{city: "Some City", street: "Some street", number: 15},
                  other_addresses: [
                    %{city: "Some City", street: "Some street", number: 15},
                    %{city: "Other city", street: "Other street", number: 10}
                  ],
                  status: :user_valid,
                  paid_amount: Decimal.new("25.0"),
                  numbers: [1, 2, 5, 10],
                  metadata: %{"key" => "value", "other_key" => "value"},
                  hex_amount: 0,
                  id_info: %{number: 123_456, type: "identity", age: 32}
                },
                %{
                  first_name: "Jane",
                  last_name: "Doe",
                  age: 32,
                  main_address: %{city: "Jane City", street: "Jane street", number: 15},
                  other_addresses: [
                    %{city: "Jane City", street: "Jane street", number: 15},
                    %{city: "Other city", street: "Other street", number: 10}
                  ],
                  status: :user_invalid,
                  paid_amount: Decimal.new("25.0"),
                  numbers: [1, 2, 5, 10],
                  metadata: %{"key" => "value", "other_key" => "value"},
                  hex_amount: 0,
                  id_info: %{number: 123_456, type: "identity", age: 32}
                }
              ]} == Parameter.load(UserTestSchema, params, many: true)

      assert {:ok,
              [
                %UserTestSchema{
                  first_name: "John",
                  last_name: "Doe",
                  age: 12,
                  main_address: %AddressTestSchema{
                    city: "Some City",
                    street: "Some street",
                    number: 15
                  },
                  other_addresses: [
                    %AddressTestSchema{city: "Some City", street: "Some street", number: 15},
                    %AddressTestSchema{city: "Other city", street: "Other street", number: 10}
                  ],
                  status: :user_valid,
                  paid_amount: Decimal.new("25.0"),
                  numbers: [1, 2, 5, 10],
                  metadata: %{"key" => "value", "other_key" => "value"},
                  hex_amount: 0,
                  id_info: %UserTestSchema.IdInfo{number: 123_456, type: "identity", age: 32}
                },
                %UserTestSchema{
                  first_name: "Jane",
                  last_name: "Doe",
                  age: 32,
                  main_address: %AddressTestSchema{
                    city: "Jane City",
                    street: "Jane street",
                    number: 15
                  },
                  other_addresses: [
                    %AddressTestSchema{city: "Jane City", street: "Jane street", number: 15},
                    %AddressTestSchema{city: "Other city", street: "Other street", number: 10}
                  ],
                  status: :user_invalid,
                  paid_amount: Decimal.new("25.0"),
                  numbers: [1, 2, 5, 10],
                  metadata: %{"key" => "value", "other_key" => "value"},
                  hex_amount: 0,
                  id_info: %UserTestSchema.IdInfo{number: 123_456, type: "identity", age: 32}
                }
              ]} == Parameter.load(UserTestSchema, params, struct: true, many: true)
    end

    test "load input as a list with invalid parameters should fail" do
      params = [
        %{
          "firstName" => "John",
          "lastName" => "Doe",
          "age" => "32a",
          "mainAddress" => %{"city" => "Some City", "street" => "Some street", "number" => "15A"},
          "otherAddresses" => [
            %{"city" => "Some City", "street" => "Some street", "number" => 15},
            %{"city" => "Other city", "street" => "Other street", "number" => 10}
          ],
          "status" => "userValids",
          "paidAmount" => 25.00,
          "numbers" => ["1", 2, 5, "10"],
          "metadata" => %{"key" => "value", "other_key" => "value"},
          "hexAmount" => "0x0",
          "idInfo" => %{
            "number" => 123_456,
            "type" => "identity"
          }
        },
        %{
          "firstName" => "Jane",
          "lastName" => "Doe",
          "age" => "32",
          "mainAddress" => %{"city" => "Jane City", "street" => "Jane street", "number" => "15"},
          "otherAddresses" => [
            %{"city" => "Jane City", "street" => "Jane street", "number" => 15},
            %{"city" => "Other city", "street" => "Other street", "number" => 10}
          ],
          "status" => "userInvalid",
          "paidAmount" => 25.00,
          "numbers" => ["1a", 2, 5, "10a"],
          "metadata" => [],
          "hexAmount" => "0x0",
          "idInfo" => %{
            "number" => 123_456,
            "type" => "identity"
          }
        }
      ]

      assert {:error,
              %{
                0 => %{
                  age: "invalid integer type",
                  main_address: %{number: "invalid integer type"},
                  status: "invalid enum type",
                  id_info: %{age: "invalid integer type"}
                },
                1 => %{
                  metadata: "invalid map type",
                  numbers: %{0 => "invalid integer type", 3 => "invalid integer type"}
                }
              }} == Parameter.load(UserTestSchema, params, many: true)
    end

    test "load schema with @fields_required: true should force required on all fields" do
      assert {:error, %{addresses: "is required", first_name: "is required"}} ==
               Parameter.load(UserRequiredSchemaTest, %{})

      assert {:error, %{first_name: "is required", addresses: %{0 => %{city: "is required"}}}} ==
               Parameter.load(UserRequiredSchemaTest, %{"addresses" => [%{}]})
    end

    test "load runtime schema with correct parameters" do
      params = %{
        "user" => "personal",
        "roles" => [
          %{
            "name" => 1,
            "permissions" => [
              %{"name" => "create"},
              %{"name" => "read"},
              %{"name" => "update"}
            ]
          },
          %{
            "name" => 2,
            "permissions" => [
              %{"name" => "create"},
              %{"name" => "read"},
              %{"name" => "update"},
              %{"name" => "delete"}
            ]
          }
        ]
      }

      assert {:ok,
              %{
                user: "personal",
                roles: [
                  %{
                    name: 1,
                    permissions: [%{name: "create"}, %{name: "read"}, %{name: "update"}]
                  },
                  %{
                    name: 2,
                    permissions: [
                      %{name: "create"},
                      %{name: "read"},
                      %{name: "update"},
                      %{name: "delete"}
                    ]
                  }
                ]
              }} = result = Parameter.load(@attr_schema, params)

      # also loading with struct should not have any effect

      assert result == Parameter.load(@attr_schema, params, struct: true)
    end

    test "load runtime schema with wrong parameters should fail" do
      params = %{
        "user" => "personal",
        "roles" => [
          %{
            "name" => "admin",
            "permissions" => [
              %{"name" => "not_create"},
              %{"name" => "unread"},
              %{"name" => "update"}
            ]
          },
          %{
            "name" => "super_admin",
            "permissions" => [
              %{"name" => "create"},
              %{"name" => "read"},
              %{"name" => "not_update"},
              %{"name" => "delete"}
            ]
          },
          %{
            "permissions" => [
              %{"name" => "create"}
            ]
          }
        ]
      }

      assert {:error,
              %{
                roles: %{
                  0 => %{
                    name: "invalid integer type",
                    permissions: %{0 => %{name: "is invalid"}, 1 => %{name: "is invalid"}}
                  },
                  1 => %{
                    name: "invalid integer type",
                    permissions: %{2 => %{name: "is invalid"}}
                  },
                  2 => %{name: "is required"}
                }
              }} == Parameter.load(@attr_schema, params)
    end

    test "nested params with valid data" do
      assert {:ok,
              %{
                nested_array: [[[1.5], [2.0]], [[5.3, 2.2]]],
                nested_map: %{a: %{a: %{a: 2, b: 3}}, b: %{b: %{a: 5, b: 2}}}
              }} ==
               Parameter.load(NestedSchemaTest, %{
                 nested_array: [[[1.5], [2.0]], [[5.3, 2.2]]],
                 nested_map: %{a: %{a: %{a: 2, b: 3}}, b: %{b: %{a: 5, b: 2}}}
               })
    end

    test "nested params with invalid data should fail" do
      assert {:error,
              %{
                nested_array: %{1 => %{0 => %{2 => "invalid float type"}}},
                nested_map: %{
                  b: %{b: %{d: "invalid integer type"}},
                  c: %{val: "invalid map type"}
                }
              }} ==
               Parameter.load(NestedSchemaTest, %{
                 nested_array: [[[1.5], [2.0]], [[5.3, 2.2, "not valid", 5.5]]],
                 nested_map: %{
                   a: %{a: %{a: 2, b: 3}},
                   b: %{b: %{a: 5, b: 2, d: "not valid"}},
                   c: %{val: "not valid"}
                 }
               })
    end

    test "nested params with invalid inner data should fail" do
      assert {:error,
              %{
                nested_array: %{
                  1 => "invalid array type",
                  0 => %{0 => "invalid array type", 1 => "invalid array type"}
                },
                nested_map: %{a: "invalid map type"}
              }} ==
               Parameter.load(NestedSchemaTest, %{
                 nested_array: [[%{}, %{}], :string],
                 nested_map: %{
                   a: []
                 }
               })
    end

    test "runtime schema with on_load returning errors should parse correctly" do
      schema =
        %{
          name: [
            type: :string,
            on_load: fn _val, _input -> {:error, "this input will always load error"} end
          ]
        }
        |> Schema.compile!()

      assert {:error, %{name: "this input will always load error"}} ==
               Parameter.load(schema, %{name: "name"})
    end
  end

  describe "dump/3" do
    test "passing wrong value should return an error" do
      assert {:error, message} = Parameter.dump(UserTestSchema, "not a map")
      assert message =~ "invalid input value %UndefinedFunctionError{"
    end

    test "validating required fields with nil and empty values" do
      assert {:ok, %{"street" => "Some street"}} == Parameter.dump(AddressTestSchema, %{})

      assert {:ok, %{"city" => nil, "street" => nil}} ==
               Parameter.dump(AddressTestSchema, %{city: nil, street: nil})

      assert {:ok, %{"city" => "", "street" => ""}} ==
               Parameter.dump(AddressTestSchema, %{city: "", street: ""})

      assert {:ok, %{"city" => "Some city", "street" => ""}} ==
               Parameter.dump(AddressTestSchema, %{city: "Some city", street: ""})

      assert {:ok, %{"city" => "Some city", "street" => nil}} ==
               Parameter.dump(AddressTestSchema, %{city: "Some city", street: nil})

      assert {:ok, %{"city" => "Some city", "street" => "Some street"}} ==
               Parameter.dump(AddressTestSchema, %{city: "Some city"})
    end

    test "validating required fields with nil and empty values with `ignore_nil` and `ignore_empty` options" do
      assert {:ok, %{"street" => "Some street"}} ==
               Parameter.dump(AddressTestSchema, %{}, ignore_nil: true, ignore_empty: true)

      assert {:ok, %{"street" => "Some street"}} ==
               Parameter.dump(AddressTestSchema, %{city: nil, street: nil},
                 ignore_nil: true,
                 ignore_empty: true
               )

      assert {:ok, %{"street" => "Some street"}} ==
               Parameter.dump(AddressTestSchema, %{city: "", street: ""},
                 ignore_nil: true,
                 ignore_empty: true
               )

      assert {:ok, %{"city" => "Some city", "street" => "Some street"}} ==
               Parameter.dump(AddressTestSchema, %{city: "Some city", street: ""},
                 ignore_nil: true,
                 ignore_empty: true
               )

      assert {:ok, %{"city" => "Some city", "street" => "Some street"}} ==
               Parameter.dump(AddressTestSchema, %{city: "Some city", street: nil},
                 ignore_nil: true,
                 ignore_empty: true
               )
    end

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
        status: :user_valid,
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
                "status" => "userValid",
                "numbers" => [1, 2, 5, 10],
                "metadata" => %{"key" => "value", "other_key" => "value"},
                "hexAmount" => 0,
                "paidAmount" => Decimal.new(1),
                "idInfo" => %{
                  "number" => 123,
                  "type" => "identity",
                  "age" => 32
                }
              }} == Parameter.dump(UserTestSchema, loaded_schema)
    end

    test "dump schema input from struct" do
      loaded_schema = %UserTestSchema{
        first_name: "John",
        last_name: "Doe",
        age: 32,
        main_address: %AddressTestSchema{
          city: "Some City",
          number: 15
        },
        other_addresses: [
          %AddressTestSchema{city: "Some City", street: "Some street", number: 15},
          %AddressTestSchema{city: "Other city", street: "Other street", number: 10}
        ],
        map_values: [%{"test" => true}],
        status: :user_valid,
        paid_amount: Decimal.new("10.5"),
        numbers: [1, 2, 5, 10],
        hex_amount: 1_087_573_706_314_634_443_003_985_449_474_964_098_995_406_820_908,
        id_info: %UserTestSchema.IdInfo{type: nil, age: nil},
        info: [%UserTestSchema.Info{id: "1", age: 12}]
      }

      assert {:ok,
              %{
                "firstName" => "John",
                "lastName" => "Doe",
                "age" => 32,
                "mainAddress" => %{
                  "city" => "Some City",
                  "street" => nil,
                  "number" => 15
                },
                "otherAddresses" => [
                  %{"city" => "Some City", "street" => "Some street", "number" => 15},
                  %{"city" => "Other city", "street" => "Other street", "number" => 10}
                ],
                "map_values" => [%{"test" => true}],
                "status" => "userValid",
                "paidAmount" => Decimal.new("10.5"),
                "numbers" => [1, 2, 5, 10],
                "metadata" => nil,
                "hexAmount" => 0,
                "idInfo" => %{"number" => nil, "type" => nil, "age" => 32},
                "info" => [%{"id" => "1", "age" => "32"}]
              }} == Parameter.dump(UserTestSchema, loaded_schema)
    end

    test "dump user schema with ignore_nil true" do
      params = %{
        first_name: "John",
        last_name: "Doe",
        age: 32,
        main_address: %{city: "Some City", street: nil, number: nil},
        other_addresses: [
          %{city: "Some City", street: "Some street", number: nil},
          %{city: "Other city", street: "Other street", number: 10}
        ],
        status: :user_valid,
        metadata: %{key: "value", other_key: nil},
        hex_amount: nil,
        id_info: %{number: "25"},
        info: [%{id: "1"}]
      }

      assert {:ok,
              %{
                "firstName" => "John",
                "lastName" => "Doe",
                "age" => 32,
                "mainAddress" => %{
                  "city" => "Some City",
                  "street" => "Some street"
                },
                "otherAddresses" => [
                  %{"city" => "Some City", "street" => "Some street"},
                  %{"city" => "Other city", "street" => "Other street", "number" => 10}
                ],
                "status" => "userValid",
                "paidAmount" => Decimal.new("1"),
                "numbers" => [1, 2],
                "metadata" => %{key: "value", other_key: nil},
                "idInfo" => %{"number" => 25, "age" => 32},
                "info" => [%{"id" => "1", "age" => "32"}],
                "hexAmount" => "0"
              }} == Parameter.dump(UserTestSchema, params, ignore_nil: true)
    end

    test "dump schema with invalid input should return error" do
      loaded_schema = %{
        first_name: "John",
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
                 metadata: "invalid map type",
                 numbers: "invalid array type",
                 other_addresses: %{
                   0 => %{number: "invalid integer type"}
                 },
                 id_info: %{age: "invalid integer type"}
               }
             } == Parameter.dump(UserTestSchema, loaded_schema)
    end

    test "dump schema with excluded fields should ignore it" do
      loaded_schema = %{
        first_name: "John",
        age: 32,
        main_address: %{city: "Some City", street: "Some street", number: 15},
        other_addresses: [
          %{city: "Some City", street: "Some street", number: 15},
          %{city: "Other city", street: "Other street", number: 10}
        ],
        status: :user_valid,
        paid_amount: Decimal.new("25.0"),
        numbers: [1, 2, 5, 10],
        metadata: %{"key" => "value", "other_key" => "value"},
        hex_amount: 0,
        id_info: %{number: 123_456, type: "identity"}
      }

      assert {:ok,
              %{
                "firstName" => "John",
                "lastName" => "",
                "age" => 32,
                "mainAddress" => %{"street" => "Some street"},
                "otherAddresses" => [
                  %{"number" => 15},
                  %{"number" => 10}
                ],
                "paidAmount" => Decimal.new("25.0"),
                "numbers" => [1, 2, 5, 10],
                "hexAmount" => 0,
                "idInfo" => %{
                  "number" => 123_456,
                  "age" => 32
                }
              }} ==
               Parameter.dump(UserTestSchema, loaded_schema,
                 exclude: [
                   :status,
                   {:main_address, [:city, :number]},
                   {:other_addresses, [:street, :city]},
                   :metadata,
                   {:id_info, [:type]}
                 ]
               )
    end

    test "ignore virtual fields when dumping" do
      params = %{
        email: "john@email.com",
        password: "123456",
        addresses: [
          %{street: "street", number: 12},
          %{street: "street_2", number: 15}
        ],
        phones: [
          %{number: "123456"},
          %{number: "654321"}
        ]
      }

      assert {:ok,
              %{
                "email" => "john@email.com",
                "addresses" => [%{"number" => 12}, %{"number" => 15}]
              }} == Parameter.dump(VirtualFieldTestSchema, params)

      assert {:ok, %{"addresses" => [%{"number" => 12}, %{"number" => 15}]}} ==
               Parameter.dump(VirtualFieldTestSchema, params,
                 exclude: [:email, {:phones, [:number]}]
               )

      assert {:ok, %{"addresses" => [%{}, %{}]}} ==
               Parameter.dump(VirtualFieldTestSchema, params,
                 exclude: [:email, {:addresses, [:number]}, {:phones, [:number]}]
               )
    end

    test "dump schema input as list" do
      loaded_schema = [
        %{
          first_name: "John",
          last_name: "Doe",
          age: 11,
          main_address: %{city: "John City", street: "John street", number: 15},
          other_addresses: [
            %{city: "John City", street: "John street", number: 15},
            %{city: "Other city", street: "Other street", number: 10}
          ],
          status: :user_valid,
          numbers: [1, 2, 5, 10],
          metadata: %{"key" => "value", "other_key" => "value"},
          hex_amount: "123123",
          id_info: %{number: 123, type: "identity"}
        },
        %{
          first_name: "Jane",
          last_name: "Doe",
          age: 32,
          main_address: %{city: "Jane City", street: "Jane street", number: 15},
          other_addresses: [
            %{city: "Jane City", street: "Jane street", number: 15},
            %{city: "Other city", street: "Other street", number: 10}
          ],
          status: :user_invalid,
          numbers: [1, 2, 5, 10],
          metadata: %{"key" => "value", "other_key" => "value"},
          hex_amount: "123123",
          paid_amount: Decimal.new(5),
          id_info: %{number: 123, type: "identity"}
        }
      ]

      assert {:ok,
              [
                %{
                  "firstName" => "John",
                  "lastName" => "Doe",
                  "age" => 11,
                  "mainAddress" => %{
                    "city" => "John City",
                    "street" => "John street",
                    "number" => 15
                  },
                  "otherAddresses" => [
                    %{"city" => "John City", "street" => "John street", "number" => 15},
                    %{"city" => "Other city", "street" => "Other street", "number" => 10}
                  ],
                  "status" => "userValid",
                  "numbers" => [1, 2, 5, 10],
                  "metadata" => %{"key" => "value", "other_key" => "value"},
                  "hexAmount" => 0,
                  "paidAmount" => Decimal.new(1),
                  "idInfo" => %{
                    "number" => 123,
                    "type" => "identity",
                    "age" => 11
                  }
                },
                %{
                  "firstName" => "Jane",
                  "lastName" => "Doe",
                  "age" => 32,
                  "mainAddress" => %{
                    "city" => "Jane City",
                    "street" => "Jane street",
                    "number" => 15
                  },
                  "otherAddresses" => [
                    %{"city" => "Jane City", "street" => "Jane street", "number" => 15},
                    %{"city" => "Other city", "street" => "Other street", "number" => 10}
                  ],
                  "status" => "userInvalid",
                  "numbers" => [1, 2, 5, 10],
                  "metadata" => %{"key" => "value", "other_key" => "value"},
                  "hexAmount" => 0,
                  "paidAmount" => Decimal.new(5),
                  "idInfo" => %{
                    "number" => 123,
                    "type" => "identity",
                    "age" => 32
                  }
                }
              ]} == Parameter.dump(UserTestSchema, loaded_schema, many: true)
    end

    test "dump schema as list with invalid input should return error " do
      loaded_schema = [
        %{
          first_name: "John",
          last_name: "Doe",
          age: 32,
          main_address: %{city: "John City", street: "John street", number: 15},
          other_addresses: [
            %{city: "John City", street: "John street", number: 15},
            %{city: "Other city", street: "Other street", number: 10}
          ],
          status: :user_valid,
          numbers: ["not number", 2, 5, "not number"],
          metadata: [],
          hex_amount: "123123",
          id_info: %{number: 123, type: "identity"}
        },
        %{
          first_name: "Jane",
          last_name: "Doe",
          age: "32not_number",
          main_address: %{city: "Jane City", street: "Jane street", number: 15},
          other_addresses: [
            %{city: "Jane City", street: "Jane street", number: "not number"},
            %{city: "Other city", street: "Other street", number: 10}
          ],
          status: :user_invalid,
          numbers: [1, 2, 5, 10],
          metadata: %{"key" => "value", "other_key" => "value"},
          hex_amount: "123123",
          id_info: %{number: 123, type: "identity"}
        }
      ]

      assert {:error,
              %{
                0 => %{
                  metadata: "invalid map type",
                  numbers: %{0 => "invalid integer type", 3 => "invalid integer type"}
                },
                1 => %{
                  age: "invalid integer type",
                  other_addresses: %{0 => %{number: "invalid integer type"}},
                  id_info: %{age: "invalid integer type"}
                }
              }} == Parameter.dump(UserTestSchema, loaded_schema, many: true)
    end

    test "dump runtime schema with correct parameters" do
      params = %{
        user: "personal",
        roles: [
          %{
            name: 1,
            permissions: [%{name: "create"}, %{name: "read"}, %{name: "update"}]
          },
          %{
            name: 2,
            permissions: [
              %{name: "create"},
              %{name: "read"},
              %{name: "update"},
              %{name: "delete"}
            ]
          }
        ]
      }

      assert {:ok,
              %{
                "user" => "personal",
                "roles" => [
                  %{
                    "name" => 1,
                    "permissions" => [
                      %{"name" => "create"},
                      %{"name" => "read"},
                      %{"name" => "update"}
                    ]
                  },
                  %{
                    "name" => 2,
                    "permissions" => [
                      %{"name" => "create"},
                      %{"name" => "read"},
                      %{"name" => "update"},
                      %{"name" => "delete"}
                    ]
                  }
                ]
              }} == Parameter.dump(@attr_schema, params)
    end

    test "dump runtime schema with wrong parameters should fail" do
      params = %{
        user: "personal",
        roles: [
          %{
            name: "permission",
            permissions: [
              %{name: "create"},
              %{name: 2},
              %{name: "delete"}
            ]
          },
          %{
            permissions: [
              %{name: "create"},
              %{name: "read"},
              %{name: "delete"}
            ]
          }
        ]
      }

      assert {:error, %{roles: %{0 => %{name: "invalid integer type"}}}} ==
               Parameter.dump(@attr_schema, params)
    end

    test "nested params with valid data" do
      assert {:ok,
              %{
                "nested_array" => [[[1.5], [2.0]], [[5.3, 2.2]]],
                "nested_map" => %{a: %{a: %{a: 2, b: 3}}, b: %{b: %{a: 5, b: 2}}}
              }} ==
               Parameter.dump(NestedSchemaTest, %{
                 nested_array: [[[1.5], [2.0]], [[5.3, 2.2]]],
                 nested_map: %{a: %{a: %{a: 2, b: 3}}, b: %{b: %{a: 5, b: 2}}}
               })
    end

    test "nested params with invalid data should fail" do
      assert {:error,
              %{
                nested_array: %{1 => %{0 => %{2 => "invalid float type"}}},
                nested_map: %{
                  b: %{b: %{d: "invalid integer type"}},
                  c: %{val: "invalid map type"}
                }
              }} ==
               Parameter.dump(NestedSchemaTest, %{
                 nested_array: [[[1.5], [2.0]], [[5.3, 2.2, "not valid", 5.5]]],
                 nested_map: %{
                   a: %{a: %{a: 2, b: 3}},
                   b: %{b: %{a: 5, b: 2, d: "not valid"}},
                   c: %{val: "not valid"}
                 }
               })
    end

    test "runtime schema with on_dump returning errors should parse correctly" do
      schema =
        %{
          name: [
            type: :string,
            on_dump: fn _val, _input -> {:error, "this input will always dump error"} end
          ]
        }
        |> Schema.compile!()

      assert {:error, %{name: "this input will always dump error"}} ==
               Parameter.dump(schema, %{name: "name"})
    end
  end

  describe "validate/3" do
    test "passing wrong value should return an error" do
      assert {:error, message} = Parameter.validate(UserTestSchema, "not a map")
      assert message =~ "invalid input value %UndefinedFunctionError{"
    end

    test "validate schema input" do
      params = %{
        first_name: "John",
        last_name: "Doe",
        age: 32,
        main_address: %{city: "Some City", street: "Some street", number: 15},
        other_addresses: [
          %{city: "Some City", street: "Some street", number: 15},
          %{city: "Other city", street: "Other street", number: 10}
        ],
        status: :user_valid,
        numbers: [1, 2, 5, 10],
        map_values: [%{"test" => "test"}],
        metadata: %{"key" => "value", "other_key" => "value"},
        hex_amount: "123123",
        id_info: %{number: 123, type: "identity"}
      }

      assert :ok == Parameter.validate(UserTestSchema, params)
    end

    test "validate schema input from struct" do
      params = %UserTestSchema{
        first_name: "John",
        last_name: "Doe",
        age: 32,
        main_address: %AddressTestSchema{
          city: "Some City",
          number: 15
        },
        other_addresses: [
          %AddressTestSchema{city: "Some City", street: "Some street", number: 15},
          %AddressTestSchema{city: "Other city", street: "Other street", number: 10}
        ],
        status: :user_valid,
        paid_amount: Decimal.new("10.5"),
        hex_amount: 1_087_573_706_314_634_443_003_985_449_474_964_098_995_406_820_908,
        id_info: %UserTestSchema.IdInfo{type: "type"},
        info: [%UserTestSchema.Info{id: "1"}]
      }

      assert :ok == Parameter.validate(UserTestSchema, params)
    end

    test "validate schema with invalid input should return error" do
      params = %{
        first_name: "John",
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
                 metadata: "invalid map type",
                 numbers: "invalid array type",
                 other_addresses: %{
                   0 => %{number: "invalid integer type", street: "invalid string type"}
                 },
                 hex_amount: "not a string",
                 last_name: "invalid string type",
                 status: "is required"
               }
             } == Parameter.validate(UserTestSchema, params)
    end

    test "ignore virtual fields when validating" do
      params = %{
        email: "johnemail.com",
        password: "123456",
        addresses: [
          %{street: "street", number: 12},
          %{street: "street_2", number: 15}
        ],
        phones: [
          %{number: "123456A"},
          %{number: "654321A"}
        ]
      }

      assert {:error, %{email: "is invalid"}} ==
               Parameter.validate(VirtualFieldTestSchema, params)

      assert :ok ==
               Parameter.validate(VirtualFieldTestSchema, params,
                 exclude: [:email, {:phones, [:number]}]
               )

      assert :ok ==
               Parameter.validate(VirtualFieldTestSchema, params,
                 exclude: [:email, {:addresses, [:number]}, {:phones, [:number]}]
               )
    end

    test "validate schema input as list" do
      params = [
        %{
          first_name: "John",
          last_name: "Doe",
          age: 32,
          main_address: %{city: "John City", street: "John street", number: 15},
          other_addresses: [
            %{city: "John City", street: "John street", number: 15},
            %{city: "Other city", street: "Other street", number: 10}
          ],
          status: :user_valid,
          numbers: [1, 2, 5, 10],
          metadata: %{"key" => "value", "other_key" => "value"},
          hex_amount: "123123",
          id_info: %{number: 123, type: "identity"}
        },
        %{
          first_name: "Jane",
          last_name: "Doe",
          age: 32,
          main_address: %{city: "Jane City", street: "Jane street", number: 15},
          other_addresses: [
            %{city: "Jane City", street: "Jane street", number: 15},
            %{city: "Other city", street: "Other street", number: 10}
          ],
          status: :user_invalid,
          numbers: [1, 2, 5, 10],
          metadata: %{"key" => "value", "other_key" => "value"},
          hex_amount: "123123",
          paid_amount: Decimal.new(5),
          id_info: %{number: 123, type: "identity"}
        }
      ]

      assert :ok == Parameter.validate(UserTestSchema, params, many: true)
    end

    test "validate schema as list with invalid input should return error " do
      loaded_schema = [
        %{
          last_name: 55,
          age: 32,
          main_address: %{city: "John City", street: "John street", number: 15},
          other_addresses: [
            %{city: "John City", street: "John street", number: 15},
            %{city: "Other city", street: "Other street", number: 10}
          ],
          status: :user_valid,
          numbers: ["not number", 2, 5, "not number"],
          metadata: [],
          hex_amount: "123123",
          id_info: %{number: 123, type: "identity"}
        },
        %{
          first_name: "Jane",
          last_name: "Doe",
          age: "32not_number",
          main_address: %{city: "Jane City", street: "Jane street", number: 15},
          other_addresses: [
            %{city: "Jane City", street: "Jane street", number: "not number"},
            %{city: "Other city", street: "Other street", number: 10}
          ],
          status: :user_invalid,
          numbers: [1, 2, 5, 10],
          metadata: %{"key" => "value", "other_key" => "value"},
          hex_amount: "123123",
          id_info: %{number: 123, type: "identity"}
        }
      ]

      assert {:error,
              %{
                0 => %{
                  first_name: "is required",
                  last_name: "invalid string type",
                  metadata: "invalid map type",
                  numbers: %{0 => "invalid integer type", 3 => "invalid integer type"}
                },
                1 => %{
                  age: "invalid integer type",
                  other_addresses: %{0 => %{number: "invalid integer type"}}
                }
              }} == Parameter.validate(UserTestSchema, loaded_schema, many: true)
    end

    test "validate runtime schema with correct parameters" do
      params = %{
        user: "personal",
        roles: [
          %{
            name: 1,
            permissions: [
              %{name: "create"},
              %{name: "read"},
              %{name: "update"}
            ]
          },
          %{
            name: 2,
            permissions: [
              %{name: "create"},
              %{name: "read"},
              %{name: "update"},
              %{name: "delete"}
            ]
          }
        ]
      }

      assert :ok == Parameter.validate(@attr_schema, params)
    end

    test "validate runtime schema with wrong parameters should fail" do
      params = %{
        user: "personal",
        roles: [
          %{
            name: 1,
            permissions: [
              %{name: "not_create"},
              %{name: "unread"},
              %{name: "update"}
            ]
          },
          %{
            name: "super_admin",
            permissions: [
              %{name: "create"},
              %{name: "read"},
              %{name: "not_update"},
              %{name: "delete"}
            ]
          },
          %{
            permissions: [
              %{name: "create"}
            ]
          }
        ]
      }

      assert {:error,
              %{
                roles: %{
                  0 => %{
                    permissions: %{0 => %{name: "is invalid"}, 1 => %{name: "is invalid"}}
                  },
                  1 => %{
                    name: "invalid integer type",
                    permissions: %{2 => %{name: "is invalid"}}
                  },
                  2 => %{name: "is required"}
                }
              }} == Parameter.validate(@attr_schema, params)
    end

    test "nested params with valid data" do
      assert :ok ==
               Parameter.validate(NestedSchemaTest, %{
                 nested_array: [[[1.5], [2.0]], [[5.3, 2.2]]],
                 nested_map: %{a: %{a: %{a: 2, b: 3}}, b: %{b: %{a: 5, b: 2}}}
               })
    end

    test "nested params with invalid data should fail" do
      assert {:error,
              %{
                nested_array: %{1 => %{0 => %{2 => "invalid float type"}}},
                nested_map: %{
                  b: %{b: %{d: "invalid integer type"}},
                  c: %{val: "invalid map type"}
                }
              }} ==
               Parameter.validate(NestedSchemaTest, %{
                 nested_array: [[[1.5], [2.0]], [[5.3, 2.2, "not valid", 5.5]]],
                 nested_map: %{
                   a: %{a: %{a: 2, b: 3}},
                   b: %{b: %{a: 5, b: 2, d: "not valid"}},
                   c: %{val: "not valid"}
                 }
               })
    end
  end
end
