defmodule CentrixCore.XmlDebitNoteBuilder do
  @moduledoc false

  alias CentrixCore.Dataset.NotaDebito

  def build_debit_note(nota_debito_params) do
    case validate_debit_note(nota_debito_params) do
      {:ok, nota_debito} ->
        {:ok,
         [
           xml: NotaDebito.to_xml(nota_debito),
           clave_acceso: nota_debito.info_tributaria.clave_acceso
         ]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_debit_note(params) do
    case NotaDebito.changeset(%NotaDebito{}, params) do
      %{valid?: true} = changeset ->
        {:ok, Ecto.Changeset.apply_changes(changeset)}

      changeset ->
        {:error, CentrixCore.ChangesetParser.format_errors(changeset)}
    end
  end
end
