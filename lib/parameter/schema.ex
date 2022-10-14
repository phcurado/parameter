defmodule Parameter.Schema do
  @moduledoc false

  alias Parameter.Field

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

  defmacro has_one(name, type, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      param(name, {:has_one, type}, opts)
    end
  end

  defmacro has_many(name, type, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      param(name, {:has_many, type}, opts)
    end
  end

  defmacro param(name, type, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      main_attrs = [name: name, type: type]
      field = Field.new!(main_attrs ++ opts)
      Module.put_attribute(__MODULE__, :param_fields, field)
      Module.put_attribute(__MODULE__, :param_struct_fields, field.name)
    end
  end

  defp mount_schema(caller, block) do
    prelude =
      quote do
        if line = Module.get_attribute(__MODULE__, :param_schema_defined) do
          raise "schema already defined for #{inspect(__MODULE__)} on line #{line}"
        end

        @param_schema_defined unquote(caller.line)

        Module.register_attribute(__MODULE__, :param_struct_fields, accumulate: true)

        unquote(block)
      end

    postlude =
      quote unquote: false do
        fields = Enum.reverse(@param_fields)

        defstruct Enum.reverse(@param_struct_fields)

        def __param__(:fields), do: unquote(Macro.escape(fields))
        def __param__(:field_names), do: unquote(Enum.map(fields, & &1.name))
        def __param__(:field_keys), do: unquote(Enum.map(fields, & &1.key))

        def __param__(:field, key) do
          Enum.find(__param__(:fields), &(&1.key == key))
        end
      end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end
end
