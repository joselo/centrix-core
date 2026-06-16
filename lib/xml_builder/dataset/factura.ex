defmodule CentrixCore.Dataset.Factura do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias CentrixCore.Dataset.Factura
  alias CentrixCore.Dataset.Factura.CampoAdicional
  alias CentrixCore.Dataset.Factura.Detalle
  alias CentrixCore.Dataset.Factura.InfoFactura
  alias CentrixCore.Dataset.Factura.InfoTributaria

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

  def to_doc(%Factura{} = factura) do
    children =
      Enum.reject(
        [
          InfoTributaria.to_doc(factura.info_tributaria),
          InfoFactura.to_doc(factura.info_factura),
          {:detalles, nil, detalles_to_doc(factura.detalles)},
          if(factura.info_adicional != [] and factura.info_adicional != nil,
            do: {:infoAdicional, nil, info_adicional_to_doc(factura.info_adicional)}
          )
        ],
        &is_nil/1
      )

    {
      :factura,
      %{id: "comprobante", version: "1.1.0"},
      children
    }
  end

  def to_xml(%Factura{} = factura) do
    factura
    |> to_doc()
    |> XmlBuilder.document()
    |> XmlBuilder.generate()
  end

  defp detalles_to_doc(detalles) do
    Enum.map(detalles, fn detalle -> Detalle.to_doc(detalle) end)
  end

  defp info_adicional_to_doc(info_adicional) do
    Enum.map(info_adicional, fn info -> CampoAdicional.to_doc(info) end)
  end
end
