defmodule UserSchema do
  use Parameter.Schema

  param do
    param :first_name, :string, key: "firstName", required: true
    param :last_name, :string, key: "lastName", required: true, default: ""
    param :age, :integer
    param :address, {:map, AddressSchema}, required: true
  end
end
