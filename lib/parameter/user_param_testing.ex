defmodule UserParam do
  use Parameter.Schema
  alias Parameter.Validators

  param do
    field :first_name, :string, key: "firstName", required: true

    field :last_name, :string,
      key: "lastName",
      load: fn param_1, _param_2 ->
        {:ok, param_1 <> "other name"}
      end

    field :email, :string, validator: &Validators.email/1

    has_one :address, Address do
      field :city, :string, required: true
      field :street, :string
      field :number, :integer
    end
  end

  def asdf() do
    params = %{
      "firstName" => "John",
      "lastName" => "Doe",
      "email" => "john@email.com",
      "address" => %{"city" => "New York", "street" => "York"}
    }

    Parameter.load(UserParam, params)
  end
end
