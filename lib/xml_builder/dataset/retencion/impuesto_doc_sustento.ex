defmodule BillingCore.Dataset.Retencion.ImpuestoDocSustento do
  @moduledoc false

  @decimals BillingCore.decimals()

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:cod_impuesto_doc_sustento, :string)
    field(:codigo_porcentaje, :string)
    field(:base_imponible, :float)
    field(:tarifa, :float)
    field(:valor_impuesto, :float)
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
      {:baseImponible, nil, :erlang.float_to_binary(impuesto.base_imponible, decimals: @decimals)},
      {:tarifa, nil, :erlang.float_to_binary(impuesto.tarifa, decimals: @decimals)},
      {:valorImpuesto, nil, :erlang.float_to_binary(impuesto.valor_impuesto, decimals: @decimals)}
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
