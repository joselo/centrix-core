defmodule BillingCore.XmlCreditNoteBuilder do
  @moduledoc false

  alias BillingCore.Dataset.NotaCredito

  def build_credit_note(nota_credito_params) do
    case validate_credit_note(nota_credito_params) do
      {:ok, nota_credito} ->
        {:ok,
         [
           xml: NotaCredito.to_xml(nota_credito),
           clave_acceso: nota_credito.info_tributaria.clave_acceso
         ]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_credit_note(params) do
    case NotaCredito.changeset(%NotaCredito{}, params) do
      %{valid?: true} = changeset ->
        {:ok, Ecto.Changeset.apply_changes(changeset)}

      changeset ->
        {:error, BillingCore.ChangesetParser.format_errors(changeset)}
    end
  end
end
