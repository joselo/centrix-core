defmodule BillingCore.Dataset.NotaCredito.InfoNotaCredito do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.NotaCredito.InfoNotaCredito
  alias BillingCore.Dataset.NotaCredito.TotalImpuesto

  @decimals BillingCore.decimals()

  embedded_schema do
    field(:fecha_emision, :date)
    field(:dir_establecimiento, :string)
    field(:tipo_identificacion_comprador, :integer)
    field(:razon_social_comprador, :string)
    field(:identificacion_comprador, :string)
    field(:contribuyente_especial, :string)
    field(:obligado_contabilidad, :string)
    field(:rise, :string)
    field(:cod_doc_modificado, :string)
    field(:num_doc_modificado, :string)
    field(:fecha_emision_doc_sustento, :date)
    field(:total_sin_impuestos, :decimal)
    field(:valor_modificacion, :decimal)
    field(:moneda, :string)
    field(:motivo, :string)

    embeds_many(:total_con_impuestos, TotalImpuesto)
  end

  def changeset(info_nota_credito, params) do
    info_nota_credito
    |> cast(params, [
      :fecha_emision,
      :dir_establecimiento,
      :tipo_identificacion_comprador,
      :razon_social_comprador,
      :identificacion_comprador,
      :contribuyente_especial,
      :obligado_contabilidad,
      :rise,
      :cod_doc_modificado,
      :num_doc_modificado,
      :fecha_emision_doc_sustento,
      :total_sin_impuestos,
      :valor_modificacion,
      :moneda,
      :motivo
    ])
    |> validate_required([
      :fecha_emision,
      :dir_establecimiento,
      :tipo_identificacion_comprador,
      :razon_social_comprador,
      :identificacion_comprador,
      :cod_doc_modificado,
      :num_doc_modificado,
      :fecha_emision_doc_sustento,
      :total_sin_impuestos,
      :valor_modificacion,
      :moneda,
      :motivo
    ])
    |> validate_length(:dir_establecimiento, max: 300)
    |> validate_number(:tipo_identificacion_comprador, greater_than_or_equal_to: 1, less_than: 100)
    |> validate_length(:razon_social_comprador, max: 300)
    |> validate_length(:identificacion_comprador, max: 20)
    |> validate_length(:contribuyente_especial, min: 3, max: 13)
    |> validate_inclusion(:obligado_contabilidad, ["SI", "NO"])
    |> validate_length(:rise, max: 40)
    |> validate_length(:cod_doc_modificado, is: 2)
    |> validate_length(:num_doc_modificado, max: 17)
    |> validate_length(:motivo, max: 300)
    |> validate_length(:moneda, max: 15)
    |> cast_embed(:total_con_impuestos, required: true, with: &TotalImpuesto.changeset/2)
  end

  def to_doc(%InfoNotaCredito{} = info_nota_credito, decimals \\ @decimals) do
    doc =
      [
        {:fechaEmision, nil, format_fecha_emision(info_nota_credito.fecha_emision)},
        {:dirEstablecimiento, nil, info_nota_credito.dir_establecimiento},
        {:tipoIdentificacionComprador, nil,
         info_nota_credito.tipo_identificacion_comprador
         |> Integer.to_string()
         |> String.pad_leading(2, "0")},
        {:razonSocialComprador, nil, info_nota_credito.razon_social_comprador},
        {:identificacionComprador, nil, info_nota_credito.identificacion_comprador},
        {:codDocModificado, nil, info_nota_credito.cod_doc_modificado},
        {:numDocModificado, nil, info_nota_credito.num_doc_modificado},
        {:fechaEmisionDocSustento, nil, format_fecha_emision(info_nota_credito.fecha_emision_doc_sustento)},
        {:totalSinImpuestos, nil,
         info_nota_credito.total_sin_impuestos |> Decimal.round(decimals) |> Decimal.to_string(:normal)},
        {:valorModificacion, nil,
         info_nota_credito.valor_modificacion |> Decimal.round(decimals) |> Decimal.to_string(:normal)},
        {:moneda, nil, info_nota_credito.moneda},
        {:totalConImpuestos, nil, total_con_impuestos_to_doc(info_nota_credito.total_con_impuestos)},
        {:motivo, nil, info_nota_credito.motivo}
      ]
      |> add_contribuyente_especial(info_nota_credito)
      |> add_rise(info_nota_credito)

    {
      :infoNotaCredito,
      nil,
      doc
    }
  end

  def to_xml(%InfoNotaCredito{} = info_nota_credito) do
    info_nota_credito
    |> to_doc()
    |> XmlBuilder.generate()
  end

  defp total_con_impuestos_to_doc(total_con_impuestos) do
    Enum.map(total_con_impuestos, fn impuesto -> TotalImpuesto.to_doc(impuesto) end)
  end

  defp format_fecha_emision(fecha_emision) do
    day = fecha_emision.day |> Integer.to_string() |> String.pad_leading(2, "0")
    month = fecha_emision.month |> Integer.to_string() |> String.pad_leading(2, "0")

    Enum.join([day, month, fecha_emision.year], "/")
  end

  defp add_contribuyente_especial(doc, %{obligado_contabilidad: "SI"} = info_nota_credito) do
    if contribuyente_especial = info_nota_credito.contribuyente_especial do
      List.insert_at(doc, 2, {:contribuyenteEspecial, nil, contribuyente_especial})
    else
      List.insert_at(doc, 2, {:obligadoContabilidad, nil, "SI"})
    end
  end

  defp add_contribuyente_especial(doc, %{obligado_contabilidad: _}), do: doc

  defp add_rise(doc, %{rise: nil}), do: doc

  defp add_rise(doc, %{rise: rise}) do
    List.insert_at(doc, 2, {:rise, nil, rise})
  end
end
