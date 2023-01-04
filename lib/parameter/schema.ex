defmodule Parameter.Schema do
  @moduledoc """
  The first step for building a schema for your data is to create a schema definition to model the external data.
  This can be achieved by using the `Parameter.Schema` macro.


  ## Schema
  The example below mimics an `User` model that have one `main_address` and a list of `phones`.

      defmodule User do
        use Parameter.Schema

        param do
          field :first_name, :string, key: "firstName", required: true
          field :last_name, :string, key: "lastName", required: true, default: ""
          has_one :main_address, Address, key: "mainAddress", required: true
          has_many :phones, Phone
        end
      end

      defmodule Address do
        use Parameter.Schema

        param do
          field :city, :string, required: true
          field :street, :string
          field :number, :integer
        end
      end

      defmodule Phone do
        use Parameter.Schema

        param do
          field :country, :string
          field :number, :integer
        end
      end

  `Parameter` offers other ways for creating a schema such as nesting the `has_one` and `has_many` fields. This require module name as the second parameter using `do` at the end:

      defmodule User do
        use Parameter.Schema

        param do
          field :first_name, :string, key: "firstName", required: true
          field :last_name, :string, key: "lastName", required: true, default: ""

          has_one :main_address, Address, key: "mainAddress", required: true do
            field :city, :string, required: true
            field :street, :string
            field :number, :integer
          end

          has_many :phones, Phone do
            field :country, :string
            field :number, :integer
          end
        end
      end

  Another possibility is avoiding creating files for a schema at all. This can be done by importing `Parameter.Schema` and using the `param/2` macro. This is useful for adding params in Phoenix controllers. For example:

      defmodule MyProjectWeb.UserController do
        use MyProjectWeb, :controller
        import Parameter.Schema

        alias MyProject.Users

        param UserParams do
          field :first_name, :string, required: true
          field :last_name, :string, required: true
        end

        def create(conn, params) do
          with {:ok, user_params} <- Parameter.load(__MODULE__.UserParams, params),
              {:ok, user} <- Users.create_user(user_params) do
            render(conn, "user.json", %{user: user})
          end
        end
      end

  It's recommended to use this approach when the schema will only be used in a single module.

  ## Runtime Schemas

  It's also possible to create schemas via runtime without relying on any macros.
  The API is almost the same comparing to the macro's examples:

      schema = %{
        first_name: [key: "firstName", type: :string, required: true],
        address: [type: {:has_one, %{street: [type: :string, required: true]}}],
        phones: [type: {:has_many, %{country: [type: :string, required: true]}}]
      } |> Parameter.Schema.compile!()

      Parameter.load(schema, %{"firstName" => "John"})
      {:ok, %{first_name: "John"}}


    The same API can also be evaluated on compile time by using module attributes:

      defmodule UserParams do
        alias Parameter.Schema

        @schema %{
          first_name: [key: "firstName", type: :string, required: true],
          address: [required: true, type: {:has_one, %{street: [type: :string, required: true]}}],
          phones: [type: {:has_many, %{country: [type: :string, required: true]}}]
        } |> Schema.compile!()

        def load(params) do
          Parameter.load(@schema, params)
        end
      end

    This makes it easy to dynamically create schemas or just avoid using any macros.

  ## Required fields

  By default, `Parameter.Schema` considers all fields to be optional when validating the schema.
  This behaviour can be changed by passing the module attribute `@fields_required true` on
  the module where the schema is declared.

  ### Example
      defmodule MyApp.UserSchema do
        use Parameter.Schema

        @fields_required true

        param do
          field :name, :string
          field :age, :integer
        end
      end

      Parameter.load(MyApp.UserSchema, %{})
      {:error, %{age: "is required", name: "is required"}}


  ## Custom field loading and dumping

  The `load` and `dump` behavior can be customized per field by implementing `on_load` or `on_dump` functions in the field definition.
  This can be useful if the field needs to be fetched or even validate in a different way than the defaults implemented by `Parameter`.
  Both functions should return `{:ok, value}` or `{:error, reason}` tuple.

  For example, imagine that there is a parameter called `full_name` in your schema that you want to customize on how it will be parsed:

      defmodule MyApp.UserSchema do
        use Parameter.Schema

        param do
          field :first_name, :string
          field :last_name, :string
          field :full_name, :string, on_load: &__MODULE__.load_full_name/2
        end

        def load_full_name(value, params) do
          # if `full_name` is not `nil` it just return the `full_name`
          if value do
            {:ok, value}
          else
            # Otherwise it will join the `first_name` and `last_name` params
            {:ok, params["first_name"] <> " " <> params["last_name"]}
          end
        end
      end

  Now when loading, the full_name field will be handled by the `load_full_name/2` function:

      Parameter.load(MyApp.UserSchema, %{first_name: "John", last_name: "Doe", full_name: nil})
      {:ok, %{first_name:  "John", full_name: "John Doe", last_name: "Doe"}}

  The same behavior is possible when dumping the schema parameters by using `on_dump/2` function:

      schema = %{
        level: [type: :integer, on_dump: fn value, _input -> {:ok, value || 0}  end]
      } |> Parameter.Schema.compile!()

      Parameter.dump(schema, %{level: nil})
      {:ok, %{"level" => 0}}
  """

  alias Parameter.Field
  alias Parameter.Schema.Compiler
  alias Parameter.Types

  @doc false
  defmacro __using__(_) do
    quote do
      import Parameter.Schema
      import Parameter.Enum

      Module.put_attribute(__MODULE__, :fields_required, false)
      Module.register_attribute(__MODULE__, :param_fields, accumulate: true)
    end
  end

  @doc false
  defmacro param(do: block) do
    mount_schema(__CALLER__, block)
  end

  @doc false
  defmacro param(module_name, do: block) do
    quote do
      Parameter.Schema.__mount_nested_schema__(
        unquote(module_name),
        __ENV__,
        unquote(Macro.escape(block))
      )
    end
  end

  @doc false
  defmacro field(name, type, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      main_attrs = [name: name, type: type]
      required_attrs = [required: @fields_required]

      field = Field.new!(main_attrs ++ required_attrs ++ opts)
      Module.put_attribute(__MODULE__, :param_fields, field)
      Module.put_attribute(__MODULE__, :param_struct_fields, field.name)
    end
  end

  @doc false
  defmacro has_one(name, module_name, opts, do: block) do
    block = Macro.escape(block)

    quote bind_quoted: [name: name, module_name: module_name, opts: opts, block: block] do
      opts = Compiler.fetch_nested_opts!(opts)
      module_name = Parameter.Schema.__mount_nested_schema__(module_name, __ENV__, block)

      has_one name, module_name, opts
    end
  end

  @doc false
  defmacro has_one(name, module_name, do: block) do
    block = Macro.escape(block)

    quote bind_quoted: [name: name, module_name: module_name, block: block] do
      module_name = Parameter.Schema.__mount_nested_schema__(module_name, __ENV__, block)

      has_one name, module_name
    end
  end

  defmacro has_one(name, type, opts) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      opts = Compiler.fetch_nested_opts!(opts)
      field name, {:has_one, type}, opts
    end
  end

  @doc false
  defmacro has_one(name, type) do
    quote bind_quoted: [name: name, type: type] do
      field name, {:has_one, type}
    end
  end

  @doc false
  defmacro has_many(name, module_name, opts, do: block) do
    block = Macro.escape(block)

    quote bind_quoted: [name: name, module_name: module_name, opts: opts, block: block] do
      opts = Compiler.fetch_nested_opts!(opts)
      module_name = Parameter.Schema.__mount_nested_schema__(module_name, __ENV__, block)

      has_many name, module_name, opts
    end
  end

  @doc false
  defmacro has_many(name, module_name, do: block) do
    block = Macro.escape(block)

    quote bind_quoted: [name: name, module_name: module_name, block: block] do
      module_name = Parameter.Schema.__mount_nested_schema__(module_name, __ENV__, block)

      has_many name, module_name
    end
  end

  defmacro has_many(name, type, opts) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      if type not in Types.base_types() do
        Compiler.fetch_nested_opts!(opts)
      end

      field name, {:has_many, type}, opts
    end
  end

  @doc false
  defmacro has_many(name, type) do
    quote bind_quoted: [name: name, type: type] do
      field name, {:has_many, type}
    end
  end

  def compile!(opts) when is_list(opts) do
    Field.new!(opts)
  end

  def compile!(schema) when is_map(schema) do
    for {name, opts} <- schema do
      {type, opts} = Keyword.pop(opts, :type, :string)
      type = compile_type(type)
      compile!([name: name, type: type] ++ opts)
    end
  end

  def compile_type({:has_one, schema}) do
    {:has_one, compile!(schema)}
  end

  def compile_type({:has_many, schema}) do
    {:has_many, compile!(schema)}
  end

  def compile_type({_not_assoc, _schema}) do
    {:error, "not a valid inner type, please use `has_one` or `has_many` for nested associations"}
  end

  def compile_type(type) when is_atom(type) do
    type
  end

  defp mount_schema(caller, block) do
    quote do
      if line = Module.get_attribute(__MODULE__, :param_schema_defined) do
        raise "param already defined for #{inspect(__MODULE__)} on line #{line}"
      end

      @param_schema_defined unquote(caller.line)

      Module.register_attribute(__MODULE__, :param_struct_fields, accumulate: true)

      unquote(block)

      defstruct Enum.reverse(@param_struct_fields)

      def __param__(:fields), do: Enum.reverse(@param_fields)

      def __param__(:field_names) do
        Enum.map(__param__(:fields), & &1.name)
      end

      def __param__(:field_keys) do
        field_keys(__param__(:fields))
      end

      def __param__(:field, key: key) do
        field_key(__param__(:fields), key)
      end

      def __param__(:field, name: name) do
        Enum.find(__param__(:fields), &(&1.name == name))
      end
    end
  end

  def fields(module) when is_atom(module) do
    module.__param__(:fields)
  end

  def fields(fields) when is_list(fields) do
    fields
  end

  def field_keys(module) when is_atom(module) do
    module.__param__(:field_keys)
  end

  def field_keys(fields) when is_list(fields) do
    Enum.map(fields, & &1.key)
  end

  def field_key(module, key) when is_atom(module) do
    module.__param__(:field, key: key)
  end

  def field_key(fields, key) when is_list(fields) do
    Enum.find(fields, &(&1.key == key))
  end

  def __mount_nested_schema__(module_name, env, block) do
    block =
      quote do
        use Parameter.Schema
        import Parameter.Schema

        Module.register_attribute(__MODULE__, :param_fields, accumulate: true)

        fields_required = Parameter.Schema.__fetch_fields_required_attr__(unquote(env.module))

        Module.put_attribute(__MODULE__, :fields_required, fields_required)

        param do
          unquote(block)
        end
      end

    module_name = Module.concat(env.module, module_name)

    Module.create(module_name, block, env)
    module_name
  end

  def __fetch_fields_required_attr__(module) do
    case Module.get_attribute(module, :fields_required) do
      nil -> false
      value -> value
    end
  end
end
