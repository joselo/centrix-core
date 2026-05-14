defmodule BillingCore.Dataset.Retencion.Retencion do
  @moduledoc false

  @decimals BillingCore.decimals()

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:codigo, :string)
    field(:codigo_retencion, :string)
    field(:base_imponible, :float)
    field(:porcentaje_retener, :float)
    field(:valor_retenido, :float)
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
      {:baseImponible, nil, :erlang.float_to_binary(retencion.base_imponible, decimals: @decimals)},
      {:porcentajeRetener, nil, :erlang.float_to_binary(retencion.porcentaje_retener, decimals: @decimals)},
      {:valorRetenido, nil, :erlang.float_to_binary(retencion.valor_retenido, decimals: @decimals)}
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
