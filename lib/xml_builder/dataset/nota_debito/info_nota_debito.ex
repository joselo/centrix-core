defmodule BillingCore.Dataset.NotaDebito.InfoNotaDebito do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.NotaDebito.Impuesto
  alias BillingCore.Dataset.NotaDebito.InfoNotaDebito
  alias BillingCore.Dataset.NotaDebito.Pago

  @decimals BillingCore.decimals()

  embedded_schema do
    field(:fecha_emision, :date)
    field(:dir_establecimiento, :string)
    field(:tipo_identificacion_comprador, :integer)
    field(:razon_social_comprador, :string)
    field(:identificacion_comprador, :string)
    field(:contribuyente_especial, :string)
    field(:obligado_contabilidad, :string)
    field(:cod_doc_modificado, :string)
    field(:num_doc_modificado, :string)
    field(:fecha_emision_doc_sustento, :date)
    field(:total_sin_impuestos, :decimal)
    field(:valor_total, :decimal)

    embeds_many(:impuestos, Impuesto)
    embeds_many(:pagos, Pago)
  end

  def changeset(info_nota_debito, params \\ %{}) do
    info_nota_debito
    |> cast(params, [
      :fecha_emision,
      :dir_establecimiento,
      :tipo_identificacion_comprador,
      :razon_social_comprador,
      :identificacion_comprador,
      :contribuyente_especial,
      :obligado_contabilidad,
      :cod_doc_modificado,
      :num_doc_modificado,
      :fecha_emision_doc_sustento,
      :total_sin_impuestos,
      :valor_total
    ])
    |> validate_required([
      :fecha_emision,
      :tipo_identificacion_comprador,
      :razon_social_comprador,
      :identificacion_comprador,
      :cod_doc_modificado,
      :num_doc_modificado,
      :fecha_emision_doc_sustento,
      :total_sin_impuestos,
      :valor_total
    ])
    |> validate_length(:dir_establecimiento, max: 300)
    |> validate_number(:tipo_identificacion_comprador, greater_than_or_equal_to: 1, less_than: 100)
    |> validate_length(:razon_social_comprador, max: 300)
    |> validate_length(:identificacion_comprador, max: 20)
    |> validate_length(:contribuyente_especial, min: 3, max: 13)
    |> validate_inclusion(:obligado_contabilidad, ["SI", "NO"])
    |> validate_length(:cod_doc_modificado, is: 2)
    |> validate_length(:num_doc_modificado, max: 17)
    |> cast_embed(:impuestos, required: true, with: &Impuesto.changeset/2)
    |> cast_embed(:pagos, required: true, with: &Pago.changeset/2)
  end

  def to_doc(%InfoNotaDebito{} = info, decimals \\ @decimals) do
    doc =
      [
        {:fechaEmision, nil, format_fecha_emision(info.fecha_emision)},
        {:tipoIdentificacionComprador, nil,
         info.tipo_identificacion_comprador
         |> Integer.to_string()
         |> String.pad_leading(2, "0")},
        {:razonSocialComprador, nil, info.razon_social_comprador},
        {:identificacionComprador, nil, info.identificacion_comprador},
        {:codDocModificado, nil, info.cod_doc_modificado},
        {:numDocModificado, nil, info.num_doc_modificado},
        {:fechaEmisionDocSustento, nil, format_fecha_emision(info.fecha_emision_doc_sustento)},
        {:totalSinImpuestos, nil, info.total_sin_impuestos |> Decimal.round(decimals) |> Decimal.to_string(:normal)},
        {:impuestos, nil, impuestos_to_doc(info.impuestos)},
        {:valorTotal, nil, info.valor_total |> Decimal.round(decimals) |> Decimal.to_string(:normal)},
        {:pagos, nil, pagos_to_doc(info.pagos)}
      ]
      |> add_dir_establecimiento(info)
      |> add_contribuyente_especial(info)
      |> add_obligado_contabilidad(info)

    {
      :infoNotaDebito,
      nil,
      doc
    }
  end

  def to_xml(%InfoNotaDebito{} = info) do
    info
    |> to_doc()
    |> XmlBuilder.generate()
  end

  defp format_fecha_emision(%Date{} = fecha_emision) do
    Timex.format!(fecha_emision, "%d/%m/%Y", :strftime)
  end

  defp impuestos_to_doc(impuestos) do
    Enum.map(impuestos, fn impuesto -> Impuesto.to_doc(impuesto) end)
  end

  defp pagos_to_doc(pagos) do
    Enum.map(pagos, fn pago -> Pago.to_doc(pago) end)
  end

  defp add_dir_establecimiento(doc, %{dir_establecimiento: nil}), do: doc

  defp add_dir_establecimiento(doc, %{dir_establecimiento: dir_establecimiento}) do
    List.insert_at(doc, 1, {:dirEstablecimiento, nil, dir_establecimiento})
  end

  defp add_contribuyente_especial(doc, %{contribuyente_especial: nil}), do: doc

  defp add_contribuyente_especial(doc, %{contribuyente_especial: contribuyente_especial}) do
    index = Enum.find_index(doc, fn {tag, _, _} -> tag == :identificacionComprador end)
    List.insert_at(doc, index + 1, {:contribuyenteEspecial, nil, contribuyente_especial})
  end

  defp add_obligado_contabilidad(doc, %{obligado_contabilidad: nil}), do: doc

  defp add_obligado_contabilidad(doc, %{obligado_contabilidad: obligado_contabilidad}) do
    index =
      case Enum.find_index(doc, fn {tag, _, _} -> tag == :contribuyenteEspecial end) do
        nil -> Enum.find_index(doc, fn {tag, _, _} -> tag == :identificacionComprador end)
        i -> i
      end

    List.insert_at(doc, index + 1, {:obligadoContabilidad, nil, obligado_contabilidad})
  end
end
