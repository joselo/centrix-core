defmodule BillingCore.XmlRetentionBuilder do
  @moduledoc false

  alias BillingCore.Dataset.CompRetencion

  def build_retention(retencion_params) do
    case validate_retention(retencion_params) do
      {:ok, retencion} ->
        {:ok,
         [
           xml: CompRetencion.to_xml(retencion),
           clave_acceso: retencion.info_tributaria.clave_acceso
         ]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_retention(params) do
    case CompRetencion.changeset(%CompRetencion{}, params) do
      %{valid?: true} = changeset ->
        {:ok, Ecto.Changeset.apply_changes(changeset)}

      changeset ->
        {:error, changeset}
    end
  end
end
