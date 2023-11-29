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

Parameter offers a similar Schema model from [Ecto](https://github.com/elixir-ecto/ecto) library for creating a schema and parsing it against external data. The main use case of this library is to parse response from external APIs but you may also use to validate parameters in Phoenix Controllers, when receiving requests to validate it's parameters. In general `Parameter` can be used to build strucutred data and deal with serialization/deserialization of data. Check the [official documentation](https://hexdocs.pm/parameter/) for more information.

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

## Validating parameters on Controllers

Parameter let's you define the shape of the data that it's expected to receive in Phoenix Controllers:

```elixir
defmodule MyProjectWeb.UserController do
  use MyProjectWeb, :controller
  import Parameter.Schema

  alias MyProject.Accounts

  param UserParams do
    field :first_name, :string, required: true
    field :last_name, :string, required: true
  end

  def create(conn, params) do
    with {:ok, user_params} <- Parameter.load(__MODULE__.UserParams, params),
        {:ok, user} <- Accounts.create_user(user_params) do
      render(conn, "user.json", %{user: user})
    end
  end
end
```

We can also use parameter for both request and response:

```elixir
defmodule MyProjectWeb.UserController do
  use MyProjectWeb, :controller
  import Parameter.Schema

  alias MyProject.Accounts
  alias MyProject.Accounts.User

  param UserCreateRequest do
    field :first_name, :string, required: true
    field :last_name, :string, required: true
  end

  param UserCreateResponse do
    # Returning the user ID created on request
    field :id, :integer
    field :last_name, :string
    field :last_name, :string
  end

  def create(conn, params) do
    with {:ok, user_request} <- Parameter.load(__MODULE__.UserCreateRequest, params),
          {:ok, %User{} = user} <- Accounts.create_user(user_request), 
          {:ok, user_response} <- Parameter.dump(__MODULE__.UserCreateResponse, user) do

        conn
        |> put_status(:created)
        |> json(%{user: user_response})
    end
  end
end
```

This example also shows that `Parameter` can dump the user response even if it comes from a different data strucutre. The `%User{}` struct on this example comes from `Ecto.Schema` and `Parameter` is able to convert it to params defined in `UserCreateResponse`.

## Runtime schemas

It's also possible to create schemas via runtime without relying on any macros. This gives great flexibility on schema creation as now `Parameter` schemas can be created and validated dynamically:

```elixir
schema = %{
  first_name: [key: "firstName", type: :string, required: true],
  address: [type: {:map, %{street: [type: :string, required: true]}}],
  phones: [type: {:array, %{country: [type: :string, required: true]}}]
} |> Parameter.Schema.compile!()

Parameter.load(schema, %{"firstName" => "John"})
{:ok, %{first_name: "John"}}
```


The same API can also be evaluated on compile time by using module attributes:

```elixir
defmodule UserParams do
  alias Parameter.Schema

  @schema %{
    first_name: [key: "firstName", type: :string, required: true],
    address: [required: true, type: {:map, %{street: [type: :string, required: true]}}],
    phones: [type: {:array, %{country: [type: :string, required: true]}}]
  } |> Schema.compile!()

  def load(params) do
    Parameter.load(@schema, params)
  end
end
```

Or dynamically creating schemas:

```elixir
defmodule EnvParser do
  alias Parameter.Schema

  def fetch!(env, opts \\ []) do
    atom_env = String.to_atom(env)
    type = Keyword.get(opts, :type, :string)
    default = Keyword.get(opts, :default)

    %{
      atom_env => [key: env, type: type, default: default, required: true]
    }
    |> Schema.compile!()
    |> Parameter.load(%{env => System.get_env(env)}, ignore_nil: true)
    |> case do
      {:ok, %{^atom_env => parsed_env}} -> parsed_env
      {:error, %{^atom_env => error}} -> raise ArgumentError, message: "#{env}: #{error}"
    end
  end
end
```

And now with this code we can dynamically fetch environment variables with `System.get_env/1`, define then as `required`, convert it to the correct type and use on our application's runtime:

```elixir
# runtime.ex
import Config

# ...

config :my_app,
  auth_enabled?: EnvParser.fetch!("AUTH_ENABLED", default: true, type: :boolean),
  api_url: EnvParser.fetch!("API_URL") # using the default type string

# ...
```

this will come in handy since you don't have to worry anymore when fetching environment variables, what will be the shape of the data and what type I will have to use or convert in the application, `Parameter` will do this automatically for you.

This small example show one of the possibilities but this can be extended depending on your use case.
A common example is to use runtime schemas when you have similar `schemas` and you want to reuse their properties across different entities:

```elixir
user_base = %{first_name: [key: "firstName", type: :string, required: true]}
admin_params = %{role: [key: "role", type: :string, required: true]}
user_admin = Map.merge(user_base, admin_params)

user_base_schema = Parameter.Schema.compile!(user_base)
user_admin_schema = Parameter.Schema.compile!(user_admin)

# Now we can use both schemas to serialize/deserialize data with `load` and `dump` parameter functions
```

For more info on how to create schemas, check the [schema documentation](https://hexdocs.pm/parameter/Parameter.Schema.html)

## License

Copyright (c) 2022, Paulo Curado.

Parameter source code is licensed under the Apache 2.0 License.