defmodule BillingCore.Dataset.LiquidacionCompra.TotalImpuesto do
  @moduledoc false

  @decimals BillingCore.decimals()

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:codigo, :integer)
    field(:codigo_porcentaje, :integer)
    field(:descuento_adicional, :decimal)
    field(:base_imponible, :decimal)
    field(:tarifa, :decimal)
    field(:valor, :decimal)
  end

  def changeset(total_impuesto, params \\ %{}) do
    total_impuesto
    |> cast(params, [
      :codigo,
      :codigo_porcentaje,
      :descuento_adicional,
      :base_imponible,
      :tarifa,
      :valor
    ])
    |> validate_required([
      :codigo,
      :codigo_porcentaje,
      :base_imponible,
      :valor
    ])
  end

  def to_doc(%BillingCore.Dataset.LiquidacionCompra.TotalImpuesto{} = total_impuesto) do
    doc =
      [
        {:codigo, nil, total_impuesto.codigo},
        {:codigoPorcentaje, nil, total_impuesto.codigo_porcentaje}
      ]
      |> add_descuento_adicional(total_impuesto)
      |> add_base_imponible(total_impuesto)
      |> add_tarifa(total_impuesto)
      |> add_valor(total_impuesto)

    {
      :totalImpuesto,
      nil,
      doc
    }
  end

  def to_xml(%BillingCore.Dataset.LiquidacionCompra.TotalImpuesto{} = total_impuesto) do
    to_doc(total_impuesto)
    |> XmlBuilder.generate()
  end

  defp add_descuento_adicional(doc, %{descuento_adicional: nil}), do: doc

  defp add_descuento_adicional(doc, %{descuento_adicional: descuento_adicional}) do
    doc ++
      [
        {:descuentoAdicional, nil,
         Decimal.round(descuento_adicional, @decimals) |> Decimal.to_string(:normal)}
      ]
  end

  defp add_base_imponible(doc, %{base_imponible: base_imponible}) do
    doc ++ [{:baseImponible, nil, Decimal.round(base_imponible, @decimals) |> Decimal.to_string(:normal)}]
  end

  defp add_tarifa(doc, %{tarifa: nil}), do: doc

  defp add_tarifa(doc, %{tarifa: tarifa}) do
    doc ++ [{:tarifa, nil, Decimal.round(tarifa, @decimals) |> Decimal.to_string(:normal)}]
  end

  defp add_valor(doc, %{valor: valor}) do
    doc ++ [{:valor, nil, Decimal.round(valor, @decimals) |> Decimal.to_string(:normal)}]
  end
end
