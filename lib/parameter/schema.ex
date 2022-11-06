defmodule Parameter.Schema do
  @moduledoc """
  The first step for building a schema for your data is to create a schema definition to model the external data.
  This can be achieved by using the `Parameter.Schema` macro. The example below mimics an `User` model that have one `main_address` and a list of `phones`.

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
  """

  alias Parameter.Field
  alias Parameter.Schema.Compiler
  alias Parameter.Types

  @doc false
  defmacro __using__(_) do
    quote do
      import Parameter.Schema
      import Parameter.Enum
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
      field = Field.new!(main_attrs ++ opts)
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
        Enum.map(__param__(:fields), & &1.key)
      end

      def __param__(:field, key: key) do
        Enum.find(__param__(:fields), &(&1.key == key))
      end

      def __param__(:field, name: name) do
        Enum.find(__param__(:fields), &(&1.name == name))
      end
    end
  end

  def __mount_nested_schema__(module_name, env, block) do
    block =
      quote do
        use Parameter.Schema

        param do
          unquote(block)
        end
      end

    module_name = Module.concat(env.module, module_name)

    Module.create(module_name, block, env)
    module_name
  end
end
