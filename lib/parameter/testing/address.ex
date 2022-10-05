defmodule AddressSchema do
  use Parameter.Schema

  param do
    param :city, :string, required: true
    param :street, :string
    param :number, :integer
  end
end
