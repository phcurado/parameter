# Parameter
<!-- MDOC !-->
`Parameter` is a library for dealing with complex datatypes by solving the following problems:
  - Schema creation and validation
  - Input data validation
  - Deserialization
  - Serialization

  ## Schema

  First step for building the schema of your data is creating the schema definition.
  This can be achived by using the `Parameter.Schema` macro.
  ```elixir
  defmodule UserSchema do
    use Parameter.Schema

    param do
      param :first_name, :string, key: "firstName", required: true
      param :last_name, :string, key: "lastName", required: true, default: ""
      param :age, :integer
      param :address, {:map, AddressSchema}, required: true
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

  Each field needs to define the type that will be parsed and the options (if any). The types available are:

  - `:string`
  - `:atom`
  - `:integer`
  - `:float`
  - `:boolean`
  - `{:map, inner_type}`
  - `{:array, inner_type}`
  - `:map`
  - `:array`
  - `:date`
  - `:time`
  - `:datetime`
  - `:naive_datetime`
  - `module`*

  \\* Any module that implements the `Parameter.Field` behaviour is elegible to be a field in the schema definition.

  The options available for the field definition are:
  - `key`: This is the key on the external source that will be converted to the param definition.
  As an example, if you receive data from an external source that uses snake case for mapping `first_name`, this flag should be `key: "firstName"`.
  If this parameter is not set it will default to the field name.
  - `default`: default value of the field.
  - `required`: defines if the field needs to be present when parsing the input.

  After the definition the schema can be validate and parsed against external parameters using the `Parameter.load/3` function.


  ## Data Deserialization

  This is a common requirement when you receive data from an external source and wants to
  validate and deserialize this data to an Elixir definition. This can be achived using `Parameter.load/2` or `Parameter.load/3` functions:

  ```elixir
  iex> params = %{
        "address" => %{"city" => "Tallinn"},
        "age" => "32",
        "firstName" => "Paulo",
        "lastName" => "Curado"
      }
  ...> Parameter.load(UserSchema, params)
    %{
      address: %{city: "Tallinn"},
      age: 32,
      first_name: "Paulo",
      last_name: "Curado"
    }
  ```

  Adding invalid data should return validation errors:

  ```elixir
  iex> params = %{
        "address" => %{"city" => "Tallinn", "number" => "123AB"},
        "age" => "AA",
        "firstName" => "Paulo",
        "lastName" => "Curado"
      }
  ...> Parameter.load(UserSchema, params)
  {:error, %{address: %{number: "invalid integer type"}, age: "invalid integer type"}}
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
- Required key: Return error when keys are not passed on a required field. Error should be: "is required".
- Default key: Implement the default validation and load option when no key are sent in the input data.
- Load returns struct: When loading input data with `Parameter.load/3` it should have a option return a struct instead of map. The API can be: `Parameter.load(Schema, params, struct: true)`
- Custom types: For now the types are fixed to the ones implemented on this library but it should be able to extend to custom types if it's passed on the schema.
- Validator: Schema should have a validator option where it can send a function with validation that returns `:ok | {:error, reason}`. Validation errors will be returned when loading the structure.
- Dump: Opposite of load.