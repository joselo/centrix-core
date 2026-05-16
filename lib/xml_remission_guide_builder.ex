defmodule BillingCore.XmlRemissionGuideBuilder do
  @moduledoc false

  alias BillingCore.Dataset.GuiaRemision

  def build_remission_guide(guia_remision_params) do
    case validate_remission_guide(guia_remision_params) do
      {:ok, guia_remision} ->
        {:ok,
         [
           xml: GuiaRemision.to_xml(guia_remision),
           clave_acceso: guia_remision.info_tributaria.clave_acceso
         ]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_remission_guide(params) do
    case GuiaRemision.changeset(%GuiaRemision{}, params) do
      %{valid?: true} = changeset ->
        {:ok, Ecto.Changeset.apply_changes(changeset)}

      changeset ->
        {:error, BillingCore.ChangesetParser.format_errors(changeset)}
    end
  end
end
