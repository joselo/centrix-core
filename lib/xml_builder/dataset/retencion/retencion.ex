defmodule BillingCore.Dataset.Retencion.Retencion do
  @moduledoc false

  @decimals BillingCore.decimals()

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:codigo, :string)
    field(:codigo_retencion, :string)
    field(:base_imponible, :decimal)
    field(:porcentaje_retener, :decimal)
    field(:valor_retenido, :decimal)
    # dividendos y compraCajBanano son opcionales y pueden agregarse luego si es necesario
  end

  def changeset(retencion, params \\ %{}) do
    retencion
    |> cast(params, [
      :codigo,
      :codigo_retencion,
      :base_imponible,
      :porcentaje_retener,
      :valor_retenido
    ])
    |> validate_required([
      :codigo,
      :codigo_retencion,
      :base_imponible,
      :porcentaje_retener,
      :valor_retenido
    ])
  end

  def to_doc(%BillingCore.Dataset.Retencion.Retencion{} = retencion) do
    doc = [
      {:codigo, nil, retencion.codigo},
      {:codigoRetencion, nil, retencion.codigo_retencion},
      {:baseImponible, nil, Decimal.round(retencion.base_imponible, @decimals) |> Decimal.to_string(:normal)},
      {:porcentajeRetener, nil, Decimal.round(retencion.porcentaje_retener, @decimals) |> Decimal.to_string(:normal)},
      {:valorRetenido, nil, Decimal.round(retencion.valor_retenido, @decimals) |> Decimal.to_string(:normal)}
    ]

    {
      :retencion,
      nil,
      doc
    }
  end

  def to_xml(%BillingCore.Dataset.Retencion.Retencion{} = retencion) do
    to_doc(retencion)
    |> XmlBuilder.generate()
  end
end
