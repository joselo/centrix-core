defmodule CentrixCore.ChangesetParser do
  @moduledoc """
  Provides functions to parse and format Ecto changeset errors.
  """

  @doc """
  Traverses an Ecto.Changeset and returns a map of formatting errors,
  including nested errors.
  """
  def format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
