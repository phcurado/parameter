defmodule Parameter.Factory.NestedSchema do
  use Parameter.Schema

  param do
    has_many :addresses, Address, required: true do
      field :street, :string, required: true
      field :number, :integer, default: 0
      field :state, :string
    end

    has_one :phone, Phone do
      field :code, :string
      field :number, :string, required: true
    end
  end
end
