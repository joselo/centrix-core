defmodule CentrixCore.Dataset.LiquidacionCompra do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias CentrixCore.Dataset.Factura.CampoAdicional
  alias CentrixCore.Dataset.Factura.InfoTributaria
  alias CentrixCore.Dataset.LiquidacionCompra
  alias CentrixCore.Dataset.LiquidacionCompra.Detalle
  alias CentrixCore.Dataset.LiquidacionCompra.InfoLiquidacionCompra

  embedded_schema do
    embeds_one(:info_tributaria, InfoTributaria)
    embeds_one(:info_liquidacion_compra, InfoLiquidacionCompra)

    embeds_many(:detalles, Detalle)
    embeds_many(:info_adicional, CampoAdicional)
  end

  def changeset(liquidacion_compra, params \\ %{}) do
    liquidacion_compra
    |> cast(params, [])
    |> cast_embed(:info_tributaria, required: true, with: &InfoTributaria.changeset/2)
    |> cast_embed(:info_liquidacion_compra,
      required: true,
      with: &InfoLiquidacionCompra.changeset/2
    )
    |> cast_embed(:detalles, required: true, with: &Detalle.changeset/2)
    |> cast_embed(:info_adicional, required: false, with: &CampoAdicional.changeset/2)
  end

  def to_doc(%LiquidacionCompra{} = liquidacion_compra) do
    doc =
      add_info_adicional(
        [
          InfoTributaria.to_doc(liquidacion_compra.info_tributaria),
          InfoLiquidacionCompra.to_doc(liquidacion_compra.info_liquidacion_compra),
          {:detalles, nil, detalles_to_doc(liquidacion_compra.detalles)}
        ],
        liquidacion_compra
      )

    {
      :liquidacionCompra,
      %{id: "comprobante", version: "1.1.0"},
      doc
    }
  end

  def to_xml(%LiquidacionCompra{} = liquidacion_compra) do
    liquidacion_compra
    |> to_doc()
    |> XmlBuilder.document()
    |> XmlBuilder.generate()
  end

  defp detalles_to_doc(detalles) do
    Enum.map(detalles, fn detalle -> Detalle.to_doc(detalle) end)
  end

  defp add_info_adicional(doc, %{info_adicional: []}), do: doc

  defp add_info_adicional(doc, %{info_adicional: info_adicional}) do
    info_adicional_doc = Enum.map(info_adicional, &CampoAdicional.to_doc/1)
    doc ++ [{:infoAdicional, nil, info_adicional_doc}]
  end
end
