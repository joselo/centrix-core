defmodule BillingCore.Dataset.NotaDebito do
  @moduledoc false

  alias BillingCore.Dataset.Factura.{
    CampoAdicional,
    InfoTributaria
  }

  alias BillingCore.Dataset.NotaDebito.{
    InfoNotaDebito,
    Motivo
  }

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    embeds_one(:info_tributaria, InfoTributaria)
    embeds_one(:info_nota_debito, InfoNotaDebito)

    embeds_many(:motivos, Motivo)
    embeds_many(:info_adicional, CampoAdicional)
  end

  def changeset(nota_debito, params \\ %{}) do
    nota_debito
    |> cast(params, [])
    |> cast_embed(:info_tributaria, required: true, with: &InfoTributaria.changeset/2)
    |> cast_embed(:info_nota_debito, required: true, with: &InfoNotaDebito.changeset/2)
    |> cast_embed(:motivos, required: true, with: &Motivo.changeset/2)
    |> cast_embed(:info_adicional, required: true, with: &CampoAdicional.changeset/2)
  end

  def to_doc(%BillingCore.Dataset.NotaDebito{} = nota_debito) do
    {
      :notaDebito,
      %{id: "comprobante", version: "1.0.0"},
      [
        InfoTributaria.to_doc(nota_debito.info_tributaria),
        InfoNotaDebito.to_doc(nota_debito.info_nota_debito),
        {:motivos, nil, motivos_to_doc(nota_debito.motivos)},
        {:infoAdicional, nil, info_adicional_to_doc(nota_debito.info_adicional)}
      ]
    }
  end

  def to_xml(%BillingCore.Dataset.NotaDebito{} = nota_debito) do
    XmlBuilder.document(to_doc(nota_debito))
    |> XmlBuilder.generate()
  end

  defp motivos_to_doc(motivos) do
    motivos
    |> Enum.map(fn motivo -> Motivo.to_doc(motivo) end)
  end

  defp info_adicional_to_doc(info_adicional) do
    info_adicional
    |> Enum.map(fn info -> CampoAdicional.to_doc(info) end)
  end
end
