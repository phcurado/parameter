defmodule Parameter.ExcludeFields do
  @moduledoc false

  @spec field_to_exclude(atom() | binary(), list()) :: :exclude | :include | {:exclude, list()}
  def field_to_exclude(field_name, exclude_fields) when is_list(exclude_fields) do
    exclude_fields
    |> Enum.find(fn
      {key, _value} -> field_name == key
      key -> field_name == key
    end)
    |> case do
      nil -> :include
      {_key, nested_values} -> {:exclude, nested_values}
      _ -> :exclude
    end
  end

  def field_to_exclude(_field_name, _exclude_fields), do: :include
end
