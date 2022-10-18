defmodule Parameter.Schema do
  @moduledoc false

  alias Parameter.Field
  alias Parameter.Schema.Compiler

  @doc false
  defmacro __using__(_) do
    quote do
      import Parameter.Schema
      Module.register_attribute(__MODULE__, :param_fields, accumulate: true)
    end
  end

  defmacro param(do: block) do
    mount_schema(__CALLER__, block)
  end

  defmacro param(module_name, do: block) do
    quote do
      Parameter.Schema.__mount_nested_schema__(
        unquote(module_name),
        __ENV__,
        unquote(Macro.escape(block))
      )
    end
  end

  defmacro field(name, type, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      main_attrs = [name: name, type: type]
      field = Field.new!(main_attrs ++ opts)
      Module.put_attribute(__MODULE__, :param_fields, field)
      Module.put_attribute(__MODULE__, :param_struct_fields, field.name)
    end
  end

  defmacro has_one(name, module_name, opts, do: block) do
    block = Macro.escape(block)

    quote bind_quoted: [name: name, module_name: module_name, opts: opts, block: block] do
      opts = Compiler.fetch_nested_opts!(opts)
      module_name = Parameter.Schema.__mount_nested_schema__(module_name, __ENV__, block)

      has_one name, module_name, opts
    end
  end

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

  defmacro has_one(name, type) do
    quote bind_quoted: [name: name, type: type] do
      field name, {:has_one, type}
    end
  end

  defmacro has_many(name, module_name, opts, do: block) do
    block = Macro.escape(block)

    quote bind_quoted: [name: name, module_name: module_name, opts: opts, block: block] do
      opts = Compiler.fetch_nested_opts!(opts)
      module_name = Parameter.Schema.__mount_nested_schema__(module_name, __ENV__, block)

      has_many name, module_name, opts
    end
  end

  defmacro has_many(name, module_name, do: block) do
    block = Macro.escape(block)

    quote bind_quoted: [name: name, module_name: module_name, block: block] do
      module_name = Parameter.Schema.__mount_nested_schema__(module_name, __ENV__, block)

      has_many name, module_name
    end
  end

  defmacro has_many(name, type, opts) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      opts = Compiler.fetch_nested_opts!(opts)
      field name, {:has_many, type}, opts
    end
  end

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

      def __param__(:field, key) do
        Enum.find(__param__(:fields), &(&1.key == key))
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
