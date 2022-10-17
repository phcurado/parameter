# Parameter
<!-- MDOC !-->
`Parameter` is a library for dealing with complex datatypes by solving the following problems:
  - Schema creation and validation
  - Input data validation
  - Deserialization
  - Serialization

## Motivation

Offer a similar Schema model from [Ecto](https://github.com/elixir-ecto/ecto) library to deal with complex data schemas. The main use case is to parse response from external apis. `Parameter` provides a well structured schema model which tries it's best to parse the external data.

## Schema

The first step for building a schema for your data is to create a schema definition.
This can be achieved by using the `Parameter.Schema` macro.

```elixir
defmodule UserSchema do
  use Parameter.Schema

  param do
    field :first_name, :string, key: "firstName", required: true
    field :last_name, :string, key: "lastName", required: true, default: ""
    field :age, :integer
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
    field :city, :string, required: true
    field :street, :string
    field :number, :integer
  end
end
```

It's also possible to avoid creating modules for nested types by using the following api:

```elixir
defmodule UserSchema do
  use Parameter.Schema

  param do
    field :first_name, :string, key: "firstName", required: true
    field :last_name, :string, key: "lastName", required: true, default: ""
    field :age, :integer
    has_one :main_address, AddressSchema, key: "mainAddress", required: true  do
      field :city, :string, required: true
      field :street, :string
      field :number, :integer
    end
  end
end
```

Another possibility is avoiding creating files for a schema at all. This can be done by importing `Parameter.Schema` and using the `param/2` macro. This is useful for adding params in Phoenix controllers. For example:

```elixir
defmodule MyProjectWeb.UserController do
  use MyProjectWeb, :controller
  import Parameter.Schema

  alias MyProject.Users

  param UserParams do
    field :first_name, :string, required: true
    field :last_name, :string, required: true
  end

  def create(conn, params) do
    with {:ok, user_params} <- Parameter.load(__MODULE__.UserParams, params),
         {:ok, user} <- Users.create_user(user_params) do
      render(conn, "user.json", %{user: user})
    end
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

\* Any module that implements the `Parameter.Parametrizable` behaviour is eligible to be a field in the schema definition.

The options available for the field definition are:
- `key`: This is the key on the external source that will be converted to the param definition.
As an example, if you receive data from an external source that uses a camel case for mapping `first_name`, this flag should be `key: "firstName"`.
If this parameter is not set it will default to the field name.
- `default`: default value of the field.
- `required`: defines if the field needs to be present when parsing the input.

After the definition, the schema can be validated and parsed against external parameters using the `Parameter.load/3` function.

## Data Deserialization

This is a common requirement when receiving data from an external source that needs validation and deserialization of data to an Elixir definition. This can be achieved using `Parameter.load/2` or `Parameter.load/3` functions:

```elixir
iex> params = %{
      "mainAddress" => %{"city" => "New York"},
      "addresses" => [%{"city" => "Rio de Janeiro"}],
      "age" => "32",
      "firstName" => "John",
      "lastName" => "Doe"
    }
...> Parameter.load(UserSchema, params)
{:ok,
 %{
   addresses: [%{city: "Rio de Janeiro"],
   age: 32,
   first_name: "John",
   last_name: "Doe",
   main_address: %{city: "New York"}
  }}
...> Parameter.load(UserSchema, params, struct: true)
{:ok,
 %UserSchema{
   addresses: [%AddressSchema{city: "Rio de Janeiro"],
   age: 32,
   first_name: "John",
   last_name: "Doe",
   main_address: %AddressSchema{city: "New York"}
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
   first_name: "is required",
   main_address: %{number: "invalid integer type"}
 }}
```

## Custom Types

For implementing custom types create a module that implements the  `Parameter.Parametrizable` behaviour.

Check the following example on how `Integer` parameter was implemented:

```elixir
defmodule IntegerCustomType do
  @moduledoc """
  Integer parameter type
  """

  use Parameter.Parametrizable

  @impl true
  # `load/1` should handle deserialization of a value
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
    {:error, "invalid integer type"}
  end

  @impl true
  # `dump/1` should handle serialization of a value
  def dump(value) do
    case validate(value) do
      :ok -> {:ok, value}
      error -> error
    end
  end

  @impl true
  # `validate/1` checks the schema during compile time. It verifies the default value if it's passed to the schema validating its type
  def validate(value) when is_integer(value) do
    :ok
  end

  def validate(_value) do
    {:error, "invalid integer type"}
  end
end
```

Add the custom module on the schema definition:

```elixir
defmodule UserSchema do
  use Parameter.Schema

  param do
    field :age, IntegerCustomType, required: true
  end
end
```

## Unknown fields
Loading will ignore fields that does not have a matching key in the schema.
This behaviour can be changed with the following options:

- `:ignore` (default): ignore unknown fields 
- `:error`: return an error with the unknown fields

Using the same user schema, adding unknow field option to error should return an error:

```elixir
iex> params = %{"user_token" => "3hgj81312312"}
...> Parameter.load(UserSchema, params, unknown: :error)
{:error, %{"user_token" => "unknown field"}}
```


## Installation


Add `parameter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parameter, "~> 0.3.0"}
  ]
end
```

Also for add this depedency inside `.formatter.exs` file:

```elixir
import_deps: [:ecto, :phoenix, :parameter],
```

## Roadmap
- Make the errors be returned on a list instead of single string.
- Validator: Schema should have a validator option where it can send a function with validation that returns `:ok | {:error, reason}`. Validation errors will be returned when loading the structure.
- Dump: Opposite of load.