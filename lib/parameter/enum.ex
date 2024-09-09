defmodule Parameter.Enum do
  @moduledoc """
  Enum type represents a group of constants that have a value with an associated key.

  ## Examples

      defmodule MyApp.UserParam do
        use Parameter.Schema

        enum Status do
          value :user_online, key: "userOnline"
          value :user_offline, key: "userOffline"
        end

        param do
          field :first_name, :string, key: "firstName"
          field :status, MyApp.UserParam.Status
        end
      end

    The `Status` enum should automatically translate the `userOnline` and `userOffline` values when loading
    to the respective atom values.
      Parameter.load(MyApp.UserParam, %{"firstName" => "John", "status" => "userOnline"})
      {:ok, %{first_name: "John", status: :user_online}}

      Parameter.dump(MyApp.UserParam, %{first_name: "John", status: :user_online})
      {:ok, %{"firstName" => "John", "status" => "userOnline"}}


  > #### `Using enum` {: .info}
  >
  > When you use the `enum` macro, `Parameter` creates a module under the hood, injecting under the current module.
  > For this reason, when referencing the enum in a Parameter field, it's required to use the full module name as shown in the examples.

    Enum also supports a shorter version if the key and value are already the same:

      defmodule MyApp.UserParam do
        ...
        enum Status, values: [:user_online,  :user_offline]
        ...
      end

      Parameter.load(MyApp.UserParam, %{"firstName" => "John", "status" => "user_online"})
      {:ok, %{first_name: "John", status: :user_online}}

    Using numbers is also allowed in enums:

      enum Status do
        value :active, key: 1
        value :pending_request, key: 2
      end

      Parameter.load(MyApp.UserParam, %{"status" => 1})
      {:ok, %{status: :active}}

    It's also possible to create enums in different modules by using the
    `enum/1` macro:

      defmodule MyApp.Status do
        import Parameter.Enum

        enum do
          value :user_online, key: "userOnline"
          value :user_offline, key: "userOffline"
        end
      end

      defmodule MyApp.UserParam do
        use Parameter.Schema
        alias MyApp.Status

        param do
          field :first_name, :string, key: "firstName"
          field :status, Status
        end
      end

    And the short version:

      enum values: [:user_online,  :user_offline]


  ## Dump and validate

  Enums can also be used for validate and dump the data. The `Parameter.validate/3` function will do strict validation, checking if the value correspond to the enum values, which are internally stored as atoms.
  `Parameter.dump/3` will stringify the enum atom value. By design the `Parameter.dump/3` doesn't perform strict validations but for enums, it checks at least if the value exists in the enum definition before dumping.

  Consider the following `Parameter.Enum` implementation:

      defmodule Currency do
        use Parameter.Schema
        enum Currencies, values: [:EUR, :USD]
        
        param do
          field :currency, __MODULE__.Currencies
        end
      end

  It's possible to check if the value provided it's a valid enum in parameter:

      iex> Parameter.validate(Currency, %{currency: :EUR})
      :ok
      iex> Parameter.validate(Currency, %{currency: :BRL})
      {:error, %{currency: "invalid enum type"}}
      # Using the string version should also return an error since it's expected enum values to be atoms
      iex> Parameter.validate(Currency, %{currency: "EUR"})
      {:error, %{currency: "invalid enum type"}}

  And for dump the data:

      iex> Parameter.dump(Currency, %{currency: :EUR})
      {:ok, %{"currency" => "EUR"}}
      iex> Parameter.dump(Currency, %{currency: :BRL})
      {:error, %{currency: "invalid enum type"}}
      # Using the string version should also return an error since it's expected enum values to be atoms
      iex> Parameter.dump(Currency, %{currency: "EUR"})
      {:error, %{currency: "invalid enum type"}}
  """

  @doc false
  defmacro enum(do: block) do
    module_block = create_module_block(block)

    quote do
      unquote(module_block)
    end
  end

  defmacro enum(values: values) do
    block =
      quote do
        Enum.map(unquote(values), fn val ->
          value(val, key: to_string(val))
        end)
      end

    quote do
      enum(do: unquote(block))
    end
  end

  @doc false
  defmacro enum(module_name, do: block) do
    module_block = create_module_block(block) |> Macro.escape()

    quote bind_quoted: [module_name: module_name, module_block: module_block] do
      module_name = Module.concat(__ENV__.module, module_name)
      Module.create(module_name, module_block, __ENV__)
    end
  end

  defmacro enum(module_name, values: values) do
    block =
      quote bind_quoted: [values: values] do
        Enum.map(values, fn val ->
          value(val, key: to_string(val))
        end)
      end

    quote do
      enum(unquote(module_name), do: unquote(block))
    end
  end

  @doc false
  defmacro value(value, key: key) do
    quote bind_quoted: [key: key, value: value] do
      Module.put_attribute(__MODULE__, :enum_values, {key, value})
    end
  end

  defp create_module_block(block) do
    quote do
      @moduledoc """
      Enum parameter type
      """
      use Parameter.Parametrizable

      Module.register_attribute(__MODULE__, :enum_values, accumulate: true)

      unquote(block)

      @impl true
      def load(value) do
        @enum_values
        |> Enum.find(fn {key, enum_value} ->
          key == value
        end)
        |> case do
          nil -> error_tuple()
          {_key, enum_value} -> {:ok, enum_value}
        end
      end

      @impl true
      def dump(value) do
        @enum_values
        |> Enum.find(fn {key, enum_value} ->
          value == enum_value
        end)
        |> case do
          nil -> error_tuple()
          {key, _value} -> {:ok, key}
        end
      end

      @impl true
      def validate(value) do
        case dump(value) do
          {:error, reason} -> {:error, reason}
          {:ok, _key} -> :ok
        end
      end

      defp error_tuple, do: {:error, "invalid enum type"}
    end
  end
end
