defmodule Parameter.Validator do
  @moduledoc false

  alias Parameter.Meta
  alias Parameter.Schema
  alias Parameter.SchemaFields
  alias Parameter.Types

  @type opts :: [exclude: list(), many: boolean()]

  @spec validate(Meta.t(), opts) :: :ok | {:error, any()}
  def validate(%Meta{input: input, schema: schema} = meta, opts) when is_map(input) do
    schema_keys = Schema.field_keys(schema)

    Enum.reduce(schema_keys, %{}, fn schema_key, errors ->
      field = Schema.field_key(schema, schema_key)

      case SchemaFields.process_map_value(meta, field, opts) do
        {:error, error} ->
          Map.put(errors, field.name, error)

        {:ok, :ignore} ->
          errors

        :ok ->
          errors
      end
    end)
    |> parse_result()
  end

  def validate(%Meta{input: input} = meta, opts) when is_list(input) do
    if Keyword.get(opts, :many) do
      SchemaFields.process_list_value(meta, input, opts)
    else
      {:error,
       "received a list with `many: false`, if a list is expected pass `many: true` on options"}
    end
  end

  def validate(meta, _opts) do
    Types.validate(meta.schema, meta.input)
  end

  defp parse_result(errors) do
    if errors == %{} do
      :ok
    else
      {:error, errors}
    end
  end
end
