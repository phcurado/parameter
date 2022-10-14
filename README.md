# Parameter
<!-- MDOC !-->
`Parameter` is a library for dealing with complex datatypes by solving the following problems:
  - Schema creation and validation
  - Input data validation
  - Deserialization
  - Serialization

## Motivation

Offer a similar Schema model from the library `Ecto` to deal with complex data schemas. The main use case is to parse response from external apis. `Parameter` provides a well structured schema model which tries it's best to parse the external data.

## Schema

The first step for building a schema for your data is to create a schema definition.
This can be achieved by using the `Parameter.Schema` macro.

```elixir
defmodule UserSchema do
  use Parameter.Schema

  param do
    param :first_name, :string, key: "firstName", required: true
    param :last_name, :string, key: "lastName", required: true, default: ""
    param :age, :integer
    has_one :main_address, AddressSchema, key: "mainAddress", required: true
    has_many :addresses, AddressSchema
  end
end
```

And the `AddressSchema`:

```elixir
defmodule AddressSchema do
  use Parameter.Schema

  param do
    param :city, :string, required: true
    param :street, :string
    param :number, :integer
  end
end
```

Each field needs to define the type that will be parsed and the options (if any). The available types are:

- `:string`
- `:atom`
- `:integer`
- `:float`
- `:boolean`
- `:map`
- `:array`
- `:date`
- `:time`
- `:datetime`
- `:naive_datetime`
- `module`*

\\* Any module that implements the `Parameter.Field` behaviour is eligible to be a field in the schema definition.

The options available for the field definition are:
- `key`: This is the key on the external source that will be converted to the param definition.
As an example, if you receive data from an external source that uses a snake case for mapping `first_name`, this flag should be `key: "firstName"`.
If this parameter is not set it will default to the field name.
- `default`: default value of the field.
- `required`: defines if the field needs to be present when parsing the input.

After the definition, the schema can be validated and parsed against external parameters using the `Parameter.load/3` function.

## Data Deserialization

This is a common requirement when you receive data from an external source and want to
validate and deserialize this data to an Elixir definition. This can be achieved using `Parameter.load/2` or `Parameter.load/3` functions:

```elixir
iex> params = %{
      "mainAddress" => %{"city" => "New York"},
      "addresses" => [%{"city" => "Rio de Janeiro"}],
      "age" => "32",
      "firstName" => "John",
      "lastName" => "Doe",
      "ASdf" => "asdf"
    }
...> Parameter.load(UserSchema, params)
{:ok,
 %{
   addresses: [%{city: "Rio de Janeiro"],
   age: 32,
   first_name: "John",
   last_name: "Doe",
   main_address: %{city: "New York"
 }}
```

Adding invalid data should return validation errors:

```elixir
iex> params = %{
      "mainAddress" => %{"city" => "New York", "number" => "123AB"},
      "addresses" => [
        %{
          "city" => "New York", 
          "number" => "123AB"
        }, 
        %{
          "city" => "Rio de Janeiro", 
          "number" => "Not number"
        }
      ],
      "age" => "AA",
      "firstName" => "John",
      "lastName" => "Doe"
    }
...> Parameter.load(UserSchema, params)
{:error,
 %{
   addresses: [
     "0": %{number: "invalid integer type"},
     "1": %{number: "invalid integer type"}
   ],
   age: "invalid integer type",
   main_address: %{number: "invalid integer type"}
 }}
```

## Custom Types

For implementing custom types create a module that implements the  `Parameter.Parametrizable` behaviour.

Check the following example on how `Integer` parameter was implemented:

```Elixir
defmodule IntegerCustomType do
  @moduledoc """
  Integer parameter type
  """

  @behaviour Parameter.Parametrizable

  @impl true
  # `load/1` is evaluated when parsing the parameters, you can do validations here and transform the data
  def load(value) when is_integer(value) do
    {:ok, value}
  end

  def load(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> {:ok, integer}
      _error -> error_tuple()
    end
  end

  def load(_value) do
    error_tuple()
  end

  @impl true
  # `validate/1` checks the schema during compile time. It verifies the default value if it's passed to the schema validating its type
  def validate(value) when is_integer(value) do
    :ok
  end

  def validate(_value) do
    error_tuple()
  end

  defp error_tuple, do: {:error, "invalid integer type"}
end
```

Custom modules can be used in `Parameter.Schema`

```Elixir
defmodule UserSchema do
  use Parameter.Schema

  param do
    param :age, IntegerCustomType, required: true
  end
end
```


## Installation


Add `parameter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parameter, "~> 0.1.0"}
  ]
end
```

## Roadmap
- Make the errors be returned on a list instead of single string.
- Validator: Schema should have a validator option where it can send a function with validation that returns `:ok | {:error, reason}`. Validation errors will be returned when loading the structure.
- Dump: Opposite of load.