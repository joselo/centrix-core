defmodule CentrixCore.Dataset.Retencion.Retencion do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias CentrixCore.Dataset.Retencion.Retencion

  @decimals CentrixCore.decimals()

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

  def to_doc(%Retencion{} = retencion) do
    doc = [
      {:codigo, nil, retencion.codigo},
      {:codigoRetencion, nil, retencion.codigo_retencion},
      {:baseImponible, nil, retencion.base_imponible |> Decimal.round(@decimals) |> Decimal.to_string(:normal)},
      {:porcentajeRetener, nil, retencion.porcentaje_retener |> Decimal.round(@decimals) |> Decimal.to_string(:normal)},
      {:valorRetenido, nil, retencion.valor_retenido |> Decimal.round(@decimals) |> Decimal.to_string(:normal)}
    ]

    {
      :retencion,
      nil,
      doc
    }
  end

  def to_xml(%Retencion{} = retencion) do
    retencion
    |> to_doc()
    |> XmlBuilder.generate()
  end
end
