if Code.ensure_loaded?(Ecto) do
  defmodule Parameter.Extensions.Changeset do
    @moduledoc """
    Extends a `param` schema to be castable as a changeset

    ## Example
    Having two modules as examples to implement changeset casting and validations with associations:

        defmodule User do
          use Parameter.Schema
          alias Parameter.Extensions.Changeset

          param do
            field :first_name, :string, key: "firstName", required: true
            field :last_name, :string, key: "lastName"
            field :email, :string
            has_one :address, Address
          end

          def changeset(params) do
            User
            |> Changeset.cast(params)
            |> Changeset.cast_assoc(:address, &Address.changeset/1)
          end
        end

        defmodule Address do
          use Parameter.Schema
          alias Parameter.Extensions.Changeset

          param do
            field :city, :string
            field :street, :string
            field :number, :integer
          end

          def changeset(params) do
            Address
            |> Changeset.cast(params)
            |> Ecto.Changeset.validate_required(:city)
            |> Ecto.Changeset.validate_required(:number)
          end
        end

    now casting the changesets:
        params = %{
          "firstName" => "John",
          "lastName" => "Doe",
          "email" => "john@email.com",
          "address" => %{"city" => "New York", "street" => "York"}
        }

        {:ok, loaded_params} = Parameter.load(User, params)
        loaded_params
        |> User.changeset()
        |> Ecto.Changeset.apply_action(:update)

        {:error,
        #Ecto.Changeset<
          action: :update,
          changes: %{
            address: %{city: "New York", street: "York"},
            email: "john@email.com",
            first_name: "John",
            last_name: "Doe"
          },
          errors: [address: [number: {"can't be blank", [validation: :required]}]],
          data: #User<>,
          valid?: false
        >}

    and with valid data:
        params = %{
          "firstName" => "John",
          "lastName" => "Doe",
          "email" => "john@email.com",
          "address" => %{"city" => "New York", "street" => "York", "number" => 10}
        }
        {:ok, loaded_params} = Parameter.load(User, params)
        loaded_params
        |> User.changeset()
        |> Ecto.Changeset.apply_action(:update)
        {:ok,
        %User{
          address: %Address{city: "New York", number: 10, street: "York"},
          email: "john@email.com",
          first_name: "John",
          last_name: "Doe"
        }}
    """

    alias Parameter.Field
    alias Parameter.Types

    def cast(schema, params) do
      types = cast_types_from_schema(schema, params)

      {schema.__struct__, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))
    end

    def cast_assoc(changeset, key, with: changeset_func) do
      field = to_string(key)

      nested_changeset = changeset_func.(changeset.params[field])

      changeset =
        if nested_changeset.valid? do
          changeset
        else
          %{changeset | valid?: false}
        end

      changes = Map.put(changeset.changes, key, nested_changeset)
      %{changeset | changes: changes}
    end

    defp cast_types_from_schema(schema, params) do
      Enum.map(schema.__param__(:fields), fn field -> flatten_params(field, params) end)
      |> Enum.reject(&(&1 == nil))
      |> Enum.into(%{})
    end

    defp flatten_params(%Field{name: name, type: {:has_one, _inner_module}}, _params) do
      {name, :map}
    end

    defp flatten_params(%Field{name: name, type: type}, _params) do
      if type in Types.base_types() do
        {name, type}
      else
        nil
      end
    end
  end
end
