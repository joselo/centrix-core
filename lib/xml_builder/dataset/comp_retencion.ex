defmodule BillingCore.Dataset.CompRetencion do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.CompRetencion
  alias BillingCore.Dataset.Factura.CampoAdicional
  alias BillingCore.Dataset.Factura.InfoTributaria
  alias BillingCore.Dataset.Retencion.DocSustento
  alias BillingCore.Dataset.Retencion.InfoCompRetencion

  embedded_schema do
    embeds_one(:info_tributaria, InfoTributaria)
    embeds_one(:info_comp_retencion, InfoCompRetencion)

    embeds_many(:docs_sustento, DocSustento)
    embeds_many(:info_adicional, CampoAdicional)
  end

  def changeset(comp_retencion, params \\ %{}) do
    comp_retencion
    |> cast(params, [])
    |> cast_embed(:info_tributaria, required: true, with: &InfoTributaria.changeset/2)
    |> cast_embed(:info_comp_retencion, required: true, with: &InfoCompRetencion.changeset/2)
    |> cast_embed(:docs_sustento, required: true, with: &DocSustento.changeset/2)
    |> cast_embed(:info_adicional, required: false, with: &CampoAdicional.changeset/2)
  end

  def to_doc(%CompRetencion{} = comp_retencion) do
    doc =
      add_info_adicional(
        [
          InfoTributaria.to_doc(comp_retencion.info_tributaria),
          InfoCompRetencion.to_doc(comp_retencion.info_comp_retencion),
          {:docsSustento, nil, docs_sustento_to_doc(comp_retencion.docs_sustento)}
        ],
        comp_retencion
      )

    {
      :comprobanteRetencion,
      %{id: "comprobante", version: "2.0.0"},
      doc
    }
  end

  def to_xml(%CompRetencion{} = comp_retencion) do
    comp_retencion
    |> to_doc()
    |> XmlBuilder.document()
    |> XmlBuilder.generate()
  end

  defp docs_sustento_to_doc(docs_sustento) do
    Enum.map(docs_sustento, fn doc_sustento -> DocSustento.to_doc(doc_sustento) end)
  end

  defp add_info_adicional(doc, %{info_adicional: []}), do: doc

  defp add_info_adicional(doc, %{info_adicional: info_adicional}) do
    info_adicional_doc = Enum.map(info_adicional, &CampoAdicional.to_doc/1)
    doc ++ [{:infoAdicional, nil, info_adicional_doc}]
  end
end
