defmodule BillingCore.Dataset.NotaCredito.InfoTributaria do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.ClaveAcceso
  alias BillingCore.Dataset.ClaveAcceso.DigitoVerificador
  alias BillingCore.Dataset.NotaCredito.InfoTributaria

  embedded_schema do
    field(:ambiente, :integer)
    field(:tipo_emision, :integer)
    field(:razon_social, :string)
    field(:nombre_comercial, :string)
    field(:ruc, :string)
    field(:clave_acceso, :string)
    field(:cod_doc, :integer)
    field(:estab, :integer)
    field(:pto_emi, :integer)
    field(:secuencial, :integer)
    field(:dir_matriz, :string)
    field(:agente_retencion, :integer)

    embeds_one(:clave, ClaveAcceso)
  end

  def changeset(info_tributaria, params \\ %{}) do
    info_tributaria
    |> cast(params, [
      :ambiente,
      :tipo_emision,
      :razon_social,
      :nombre_comercial,
      :ruc,
      :cod_doc,
      :estab,
      :pto_emi,
      :secuencial,
      :dir_matriz,
      :agente_retencion
    ])
    |> validate_required([
      :ambiente,
      :tipo_emision,
      :razon_social,
      :nombre_comercial,
      :ruc,
      :cod_doc,
      :estab,
      :pto_emi,
      :secuencial,
      :dir_matriz
    ])
    |> cast_embed(:clave, required: true, with: &ClaveAcceso.changeset/2)
    |> generate_clave_acceso()
  end

  def to_doc(%InfoTributaria{} = info_tributaria) do
    cod_doc = info_tributaria.cod_doc |> Integer.to_string() |> String.pad_leading(2, "0")
    estab = info_tributaria.estab |> Integer.to_string() |> String.pad_leading(3, "0")
    pto_emi = info_tributaria.pto_emi |> Integer.to_string() |> String.pad_leading(3, "0")
    secuencial = info_tributaria.secuencial |> Integer.to_string() |> String.pad_leading(9, "0")

    doc =
      add_agente_retencion(
        [
          {:ambiente, nil, info_tributaria.ambiente},
          {:tipoEmision, nil, info_tributaria.tipo_emision},
          {:razonSocial, nil, info_tributaria.razon_social},
          {:nombreComercial, nil, info_tributaria.nombre_comercial},
          {:ruc, nil, info_tributaria.ruc},
          {:claveAcceso, nil, info_tributaria.clave_acceso},
          {:codDoc, nil, cod_doc},
          {:estab, nil, estab},
          {:ptoEmi, nil, pto_emi},
          {:secuencial, nil, secuencial},
          {:dirMatriz, nil, info_tributaria.dir_matriz}
        ],
        info_tributaria
      )

    {
      :infoTributaria,
      nil,
      doc
    }
  end

  def to_xml(%InfoTributaria{} = info_tributaria) do
    info_tributaria
    |> to_doc()
    |> XmlBuilder.generate()
  end

  defp generate_clave_acceso(%Ecto.Changeset{} = changeset) do
    case Ecto.Changeset.fetch_change(changeset, :clave) do
      {:ok, clave} ->
        clave_acceso = DigitoVerificador.generate(clave.changes)
        Ecto.Changeset.put_change(changeset, :clave_acceso, clave_acceso)

      :error ->
        changeset
    end
  end

  defp add_agente_retencion(doc, %{agente_retencion: nil}), do: doc

  defp add_agente_retencion(doc, %{agente_retencion: agente_retencion}) do
    agente_retencion = agente_retencion |> Integer.to_string() |> String.pad_leading(8, "0")

    List.insert_at(doc, 2, {:agente_retencion, nil, agente_retencion})
  end
end
