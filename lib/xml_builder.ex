defmodule BillingCore.XmlBuilder do
  @moduledoc false

  alias BillingCore.Dataset.Factura

  def build_invoice(factura_params) do
    case validate_invoice(factura_params) do
      {:ok, factura} ->
        {:ok, [xml: Factura.to_xml(factura), clave_acceso: factura.info_tributaria.clave_acceso]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_invoice(params) do
    case Factura.changeset(%Factura{}, params) do
      %{valid?: true} = changeset ->
        {:ok, Ecto.Changeset.apply_changes(changeset)}

      changeset ->
        {:error, BillingCore.ChangesetParser.format_errors(changeset)}
    end
  end
end
