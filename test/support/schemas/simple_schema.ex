defmodule Parameter.Factory.SimpleSchema do
  use Parameter.Schema

  param do
    field :first_name, :string, required: true
    field :last_name, :string
    field :age, :integer, default: 0
  end
end
