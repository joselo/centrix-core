defmodule BillingCore.Dataset.NotaDebito do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.Factura.CampoAdicional
  alias BillingCore.Dataset.Factura.InfoTributaria
  alias BillingCore.Dataset.NotaDebito
  alias BillingCore.Dataset.NotaDebito.InfoNotaDebito
  alias BillingCore.Dataset.NotaDebito.Motivo

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
    |> cast_embed(:info_adicional, with: &CampoAdicional.changeset/2)
  end

  def to_doc(%NotaDebito{} = nota_debito) do
    children =
      Enum.reject(
        [
          InfoTributaria.to_doc(nota_debito.info_tributaria),
          InfoNotaDebito.to_doc(nota_debito.info_nota_debito),
          {:motivos, nil, motivos_to_doc(nota_debito.motivos)},
          if(nota_debito.info_adicional != [] and nota_debito.info_adicional != nil,
            do: {:infoAdicional, nil, info_adicional_to_doc(nota_debito.info_adicional)}
          )
        ],
        &is_nil/1
      )

    {
      :notaDebito,
      %{id: "comprobante", version: "1.0.0"},
      children
    }
  end

  def to_xml(%NotaDebito{} = nota_debito) do
    nota_debito
    |> to_doc()
    |> XmlBuilder.document()
    |> XmlBuilder.generate()
  end

  defp motivos_to_doc(motivos) do
    Enum.map(motivos, fn motivo -> Motivo.to_doc(motivo) end)
  end

  defp info_adicional_to_doc(info_adicional) do
    Enum.map(info_adicional, fn info -> CampoAdicional.to_doc(info) end)
  end
end
