defmodule Parameter do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias Parameter.Dumper
  alias Parameter.Loader
  alias Parameter.Types

  @unknown_opts [:error, :ignore]

  @spec load(module() | atom(), map(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def load(schema, input, opts \\ []) do
    opts = parse_opts(opts)
    Loader.load(schema, input, opts)
  end

  @spec dump(module() | atom(), map()) :: {:ok, any()} | {:error, any()}
  def dump(schema, input) when is_map(input) do
    Dumper.dump(schema, input)
  end

  defp parse_opts(opts) do
    unknown = Keyword.get(opts, :unknown, :ignore)

    if unknown not in @unknown_opts do
      raise("unknown field options should be #{inspect(@unknown_opts)}")
    end

    struct = Keyword.get(opts, :struct, false)

    Types.validate!(:boolean, struct)

    [struct: struct, unknown: unknown]
  end
end
