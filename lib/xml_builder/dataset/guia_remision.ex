defmodule BillingCore.Dataset.GuiaRemision do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.Factura.CampoAdicional
  alias BillingCore.Dataset.Factura.InfoTributaria
  alias BillingCore.Dataset.GuiaRemision
  alias BillingCore.Dataset.GuiaRemision.Destinatario
  alias BillingCore.Dataset.GuiaRemision.InfoGuiaRemision

  embedded_schema do
    embeds_one(:info_tributaria, InfoTributaria)
    embeds_one(:info_guia_remision, InfoGuiaRemision)

    embeds_many(:destinatarios, Destinatario)
    embeds_many(:info_adicional, CampoAdicional)
  end

  def changeset(guia_remision, params \\ %{}) do
    guia_remision
    |> cast(params, [])
    |> cast_embed(:info_tributaria, required: true, with: &InfoTributaria.changeset/2)
    |> cast_embed(:info_guia_remision, required: true, with: &InfoGuiaRemision.changeset/2)
    |> cast_embed(:destinatarios, required: true, with: &Destinatario.changeset/2)
    |> cast_embed(:info_adicional, required: false, with: &CampoAdicional.changeset/2)
  end

  def to_doc(%GuiaRemision{} = guia_remision) do
    doc =
      add_info_adicional(
        [
          InfoTributaria.to_doc(guia_remision.info_tributaria),
          InfoGuiaRemision.to_doc(guia_remision.info_guia_remision),
          {:destinatarios, nil, destinatarios_to_doc(guia_remision.destinatarios)}
        ],
        guia_remision
      )

    {
      :guiaRemision,
      %{id: "comprobante", version: "1.0.0"},
      doc
    }
  end

  def to_xml(%GuiaRemision{} = guia_remision) do
    guia_remision
    |> to_doc()
    |> XmlBuilder.document()
    |> XmlBuilder.generate()
  end

  defp destinatarios_to_doc(destinatarios) do
    Enum.map(destinatarios, fn destinatario -> Destinatario.to_doc(destinatario) end)
  end

  defp add_info_adicional(doc, %{info_adicional: []}), do: doc

  defp add_info_adicional(doc, %{info_adicional: info_adicional}) do
    info_adicional_doc = Enum.map(info_adicional, &CampoAdicional.to_doc/1)
    doc ++ [{:infoAdicional, nil, info_adicional_doc}]
  end
end
