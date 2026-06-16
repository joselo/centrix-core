defmodule CentrixCore.Dataset.Retencion.ImpuestoDocSustento do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias CentrixCore.Dataset.Retencion.ImpuestoDocSustento

  @decimals CentrixCore.decimals()

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

  def to_doc(%ImpuestoDocSustento{} = impuesto) do
    doc = [
      {:codImpuestoDocSustento, nil, impuesto.cod_impuesto_doc_sustento},
      {:codigoPorcentaje, nil, impuesto.codigo_porcentaje},
      {:baseImponible, nil, impuesto.base_imponible |> Decimal.round(@decimals) |> Decimal.to_string(:normal)},
      {:tarifa, nil, impuesto.tarifa |> Decimal.round(@decimals) |> Decimal.to_string(:normal)},
      {:valorImpuesto, nil, impuesto.valor_impuesto |> Decimal.round(@decimals) |> Decimal.to_string(:normal)}
    ]

    {
      :impuestoDocSustento,
      nil,
      doc
    }
  end

  def to_xml(%ImpuestoDocSustento{} = impuesto) do
    impuesto
    |> to_doc()
    |> XmlBuilder.generate()
  end
end
