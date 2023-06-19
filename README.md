# Parameter

<img src="logo.png" alt="parameter" width="150">

[![CI](https://github.com/phcurado/parameter/workflows/ci/badge.svg?branch=main)](https://github.com/phcurado/parameter/actions?query=branch%3Amain+workflow%3Aci)
[![Coverage Status](https://coveralls.io/repos/github/phcurado/parameter/badge.svg?branch=main)](https://coveralls.io/github/phcurado/parameter?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/parameter)](https://hex.pm/packages/parameter)
[![HexDocs.pm](https://img.shields.io/badge/Docs-HexDocs-blue)](https://hexdocs.pm/parameter)
[![License](https://img.shields.io/hexpm/l/parameter.svg)](https://hex.pm/packages/parameter)


`Parameter` helps you shape data from external sources into Elixir internal types. Use it to deal with any external data in general, such as API integrations, parsing user input, or validating data that comes into your system.

  `Parameter` offers the following helpers:
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

Parameter offers a similar Schema model from [Ecto](https://github.com/elixir-ecto/ecto) library to deal with parameters. The main use case is to parse response from external APIs. This library provides a well structured schema model which tries to parse the external data. Check the [official documentation](https://hexdocs.pm/parameter/) for more information.


## Installation


Add `parameter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parameter, "~> 0.13"}
  ]
end
```

add `:parameter` on `.formatter.exs`:

```elixir
import_deps: [:parameter]
```

For `Parameter` with `Ecto` integration check out the [parameter_ecto](https://github.com/phcurado/parameter_ecto) project.

## License

Copyright (c) 2022, Paulo Curado.

Parameter source code is licensed under the Apache 2.0 License.