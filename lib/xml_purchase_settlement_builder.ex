defmodule CentrixCore.XmlPurchaseSettlementBuilder do
  @moduledoc false

  alias CentrixCore.Dataset.LiquidacionCompra

  def build_purchase_settlement(liquidacion_compra_params) do
    case validate_purchase_settlement(liquidacion_compra_params) do
      {:ok, liquidacion_compra} ->
        {:ok,
         [
           xml: LiquidacionCompra.to_xml(liquidacion_compra),
           clave_acceso: liquidacion_compra.info_tributaria.clave_acceso
         ]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_purchase_settlement(params) do
    case LiquidacionCompra.changeset(%LiquidacionCompra{}, params) do
      %{valid?: true} = changeset ->
        {:ok, Ecto.Changeset.apply_changes(changeset)}

      changeset ->
        {:error, CentrixCore.ChangesetParser.format_errors(changeset)}
    end
  end
end
