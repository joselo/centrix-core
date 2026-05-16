defmodule BillingCore.Dataset.Retencion.ImpuestoDocSustento do
  @moduledoc false

  @decimals BillingCore.decimals()

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:cod_impuesto_doc_sustento, :string)
    field(:codigo_porcentaje, :string)
    field(:base_imponible, :decimal)
    field(:tarifa, :decimal)
    field(:valor_impuesto, :decimal)
  end

  def changeset(impuesto, params \\ %{}) do
    impuesto
    |> cast(params, [
      :cod_impuesto_doc_sustento,
      :codigo_porcentaje,
      :base_imponible,
      :tarifa,
      :valor_impuesto
    ])
    |> validate_required([
      :cod_impuesto_doc_sustento,
      :codigo_porcentaje,
      :base_imponible,
      :tarifa,
      :valor_impuesto
    ])
  end

  def to_doc(%BillingCore.Dataset.Retencion.ImpuestoDocSustento{} = impuesto) do
    doc = [
      {:codImpuestoDocSustento, nil, impuesto.cod_impuesto_doc_sustento},
      {:codigoPorcentaje, nil, impuesto.codigo_porcentaje},
      {:baseImponible, nil, Decimal.round(impuesto.base_imponible, @decimals) |> Decimal.to_string(:normal)},
      {:tarifa, nil, Decimal.round(impuesto.tarifa, @decimals) |> Decimal.to_string(:normal)},
      {:valorImpuesto, nil, Decimal.round(impuesto.valor_impuesto, @decimals) |> Decimal.to_string(:normal)}
    ]

    {
      :impuestoDocSustento,
      nil,
      doc
    }
  end

  def to_xml(%BillingCore.Dataset.Retencion.ImpuestoDocSustento{} = impuesto) do
    to_doc(impuesto)
    |> XmlBuilder.generate()
  end
end
