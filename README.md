# Parameter

<p align="center"><img src="logo.png" alt="parameter" height="300px"></p>

`Parameter` is a library for dealing with complex datatypes by solving the following problems:
  - Schema creation and validation
  - Input data validation
  - Deserialization
  - Serialization

## Examples

```elixir
defmodule UserParam do
  use Parameter.Schema
  alias Parameter.Validators

  param do
    field :first_name, :string, key: "firstName", required: true
    field :last_name, :string, key: "lastName"
    field :email, :string, validator: &Validators.email/1
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
params = %{
  "firstName" => "John",
  "lastName" => "Doe",
  "email" => "john@email.com",
  "address" => %{"city" => "New York", "street" => "York"}
}
Parameter.load(UserParam, params)
{:ok, %{
  first_name: "John",
  last_name: "Doe",
  email: "john@email.com",
  address: %{city: "New York", street: "York"}
}}
```

or Dump (serialize) a populated schema to params:

```elixir
schema = %{
  first_name: "John",
  last_name: "Doe",
  email: "john@email.com",
  address: %{city: "New York", street: "York"}
}

Parameter.dump(UserParam, params)
{:ok,
 %{
    "firstName" => "John",
    "lastName" => "Doe",
    "email" => "john@email.com",
    "address" => %{"city" => "New York", "street" => "York"}
}}
```

Parameter offers a similar Schema model from [Ecto](https://github.com/elixir-ecto/ecto) library to deal with parameters. The main use case is to parse response from external apis. This library provides a well structured schema model which tries to parse the external data. Check the [official documentation](https://hexdocs.pm/parameter/) for more information.


## Installation


Add `parameter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parameter, "~> 0.6"}
  ]
end
```

add `:parameter` on `.formatter.exs`:

```elixir
import_deps: [:ecto, :phoenix, ..., :parameter],
```

For `Parameter` with `Ecto` integration check out the [parameter_ecto](https://github.com/phcurado/parameter_ecto) project.
