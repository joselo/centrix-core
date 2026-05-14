defmodule BillingCore.Dataset.Factura do
  @moduledoc false

  alias BillingCore.Dataset.Factura.{
    CampoAdicional,
    Detalle,
    InfoFactura,
    InfoTributaria
  }

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    embeds_one(:info_tributaria, InfoTributaria)
    embeds_one(:info_factura, InfoFactura)

    embeds_many(:detalles, Detalle)
    embeds_many(:info_adicional, CampoAdicional)
  end

  def changeset(factura, params \\ %{}) do
    factura
    |> cast(params, [])
    |> cast_embed(:info_tributaria, required: true, with: &InfoTributaria.changeset/2)
    |> cast_embed(:info_factura, required: true, with: &InfoFactura.changeset/2)
    |> cast_embed(:detalles, required: true, with: &Detalle.changeset/2)
    |> cast_embed(:info_adicional, with: &CampoAdicional.changeset/2)
  end

  def to_doc(%BillingCore.Dataset.Factura{} = factura) do
    children =
      [
        InfoTributaria.to_doc(factura.info_tributaria),
        InfoFactura.to_doc(factura.info_factura),
        {:detalles, nil, detalles_to_doc(factura.detalles)},
        if(factura.info_adicional != [] and factura.info_adicional != nil,
          do: {:infoAdicional, nil, info_adicional_to_doc(factura.info_adicional)}
        )
      ]
      |> Enum.reject(&is_nil/1)

    {
      :factura,
      %{id: "comprobante", version: "1.1.0"},
      children
    }
  end


  def to_xml(%BillingCore.Dataset.Factura{} = factura) do
    XmlBuilder.document(to_doc(factura))
    |> XmlBuilder.generate()
  end

  defp detalles_to_doc(detalles) do
    detalles
    |> Enum.map(fn detalle -> Detalle.to_doc(detalle) end)
  end

  defp info_adicional_to_doc(info_adicional) do
    info_adicional
    |> Enum.map(fn info -> CampoAdicional.to_doc(info) end)
  end
end
