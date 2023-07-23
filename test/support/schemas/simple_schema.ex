defmodule Parameter.Factory.SimpleSchema do
  use Parameter.Schema

  param do
    field :first_name, :string, key: "firstName", required: true
    field :last_name, :string, key: "lastName"
    field :age, :integer, default: 0
  end
end
