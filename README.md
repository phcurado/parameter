# Parameter
<!-- MDOC !-->
`Parameter` is a library for dealing with complex datatypes by solving the following problems:
  - Schema creation and validation
  - Input data validation
  - Deserialization
  - Serialization


First step is to create a schema

```elixir
defmodule User do
  use Parameter.Schema
  alias Parameter.Validators

  param do
    field :first_name, :string, key: "firstName", required: true
    field :last_name, :string, key: "lastName"
    field :email, :string, validator: &Validators.email(&1)
    has_one :address, Address do
      field :city, :string, required: true
      field :street, :string
      field :number, :integer
    end
  end
end
```

Load (deserialize) the schema against external parameters:

```elixir
iex> params = %{
      "firstName" => "John",
      "lastName" => "Doe",
      "email" => "john@email.com",
      "address" => %{"city" => "New York", "street" => "York"}
    }
...> Parameter.load(User, params)
{:ok, %{
  first_name: "John",
  last_name: "Doe",
  email: "john@email.com",
  main_address: %{city: "New York", street: "York"}
}}
```

or Dump (serialize) a populated schema to params:

```elixir
iex> schema = %{
    first_name: "John",
    last_name: "Doe",
    email: "john@email.com",
    main_address: %{city: "New York", street: "York"}
  }
...> Parameter.dump(User, params)
{:ok,
 %{
    "firstName" => "John",
    "lastName" => "Doe",
    "email" => "john@email.com",
    "address" => %{"city" => "New York", "street" => "York"}
}}
```

## Installation


Add `parameter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parameter, "~> 0.5"}
  ]
end
```

add `:parameter` on `.formatter.exs`:

```elixir
import_deps: [:ecto, :phoenix, ..., :parameter],
```


## Motivation

Offer a similar Schema model from [Ecto](https://github.com/elixir-ecto/ecto) library to deal with complex data schemas. The main use case is to parse response from external apis. `Parameter` provides a well structured schema model which tries it's best to parse the external data.

## Data Deserialization

This is a common requirement when receiving data from an external source that needs validation and deserialization of data to an Elixir definition. This can be achieved using `Parameter.load/2` or `Parameter.load/3` functions:

```elixir
iex> params = %{
      "mainAddress" => %{"city" => "New York"},
      "phones" => [%{"country" => "USA", "number" => "123456789"}],
      "firstName" => "John",
      "lastName" => "Doe"
    }
...> Parameter.load(User, params)
{:ok,
 %{
    first_name: "John",
    last_name: "Doe",
    main_address: %{city: "New York"},
    phones: [%{country: "USA", number: 123456789}]
  }}
```

Return struct fields

```elixir 
...> Parameter.load(User, params, struct: true)
{:ok,
 %User{
   first_name: "John",
   last_name: "Doe",
   main_address: %Address{city: "New York", number: nil, street: nil},
   phones: [%Phone{country: "USA", number: 123456789}]
 }}
```

Invalid data should return validation errors:

```elixir
iex> params = %{
      "mainAddress" => %{"city" => "New York", "number" => "123AB"},
      "phones" => [
        %{
          "country" => "USA", 
          "number" => "123AB"
        }, 
        %{
          "country" => "Brazil", 
          "number" => "Not number"
        }
      ],
      "lastName" => "Doe"
    }
...> Parameter.load(User, params)
{:error,
 %{
   first_name: "is required",
   main_address: %{number: "invalid integer type"},
   phones: [
     "0": %{number: "invalid integer type"},
     "1": %{number: "invalid integer type"}
   ]
 }}
```

The options for `Parameter.load/3` are:
  - `struct`: If `true` returns the response with elixir structs. `false` uses plain maps.
  - `unknown`: Defines the behaviour when dealing with unknown fields on input data. The options are `:ignore` and `:error` 

## Data Serialization

This is a common requirement when dealing with internal data that needs to be send to an external source. This can be achieved using `Parameter.dump/2` function:

```elixir 
iex> loaded_params = %{
  phones: [%{country: "USA", number: 123456789}],
  first_name: "John",
  last_name: "Doe",
  main_address: %{city: "New York"}
}
...> Parameter.dump(User, loaded_params)
{:ok,
 %{
   "firstName" => "John",
   "lastName" => "Doe",
   "mainAddress" => %{"city" => "New York"},
   "phones" => [%{"country" => "USA", "number" => 123456789}]
 }}
```

## Unknown fields
Loading will ignore fields that does not have a matching key in the schema.
This behaviour can be changed with the following options:

- `:ignore` (default): ignore unknown fields 
- `:error`: return an error with the unknown fields

Using the same user schema, adding unknow field option to error should return an error:

```elixir
iex> params = %{"user_token" => "3hgj81312312"}
...> Parameter.load(User, params, unknown: :error)
{:error, %{"user_token" => "unknown field"}}
```

## Validation
Parameter comes with a set of validators to validate the schema after loading. The implemented validators are described in the module `Parameter.Validators`.

```elixir
defmodule User do
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
  end


  # To add a custom validator create a function with arity 1 or 2.
  # The first parameter is always the field value and the second (and optional)
  # parameter is a `Keyword` list that will be used to pass values on the schema
  # The function must always return `:ok` or `{:error, reason}`
  def is_equal(value, to: to_value) do
    if value == to_value do
      :ok
    else
      {:error, "not equal"}
    end
  end
end
```

Sending wrong parameters:

```elixir
iex> params = %{
  "email" => "not email",
  "age" => "12",
  "code" => "asdf",
  "user_code" => "12345",
  "permission" => "super_admin"
}
...> Parameter.load(User, params)
{:error,
 %{
   age: "is invalid",
   code: "is invalid",
   email: "is invalid",
   permission: "is invalid",
   user_code: "not equal"
 }}
```

Correct input should result in the schema loaded correctly:

```elixir
iex> params = %{
  "email" => "john@email.com",
  "age" => "22",
  "code" => "code:13234",
  "permission" => "admin",
  "user_code" => "0000"
}
...> Parameter.load(User, params)
{:ok,
 %{
   age: 22,
   code: "code:13234",
   email: "john@email.com",
   permission: :admin,
   user_code: "0000"
 }}
```

## Excluding fields on serialization and deserialization


Pass the `exclude` key on the third argument of `Parameter.load/3` or `Parameter.dump/3` with a list of the fields to be excluded. Those fields won't be considered when serializing/deserializing the parameters.

```elixir
iex> params = %{
      "firstName" => "John",
      "lastName" => "Doe",
      "email" => "john@email.com",
      "address" => %{"city" => "New York", "street" => "York"}
    }
...> Parameter.load(User, params, exclude: [:first_name])
{:ok, %{
  last_name: "Doe",
  email: "john@email.com",
  address: %{city: "New York", street: "York"}
}}

...> Parameter.load(User, params, exclude: [:first_name, {:address, [:street]}])
{:ok, %{
  last_name: "Doe",
  email: "john@email.com",
  address: %{city: "New York"}
}}
```
