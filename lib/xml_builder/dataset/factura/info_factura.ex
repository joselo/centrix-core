defmodule BillingCore.Dataset.Factura.InfoFactura do
  @moduledoc false

  @decimals BillingCore.decimals()

  alias BillingCore.Dataset.Factura.{Pago, TotalImpuesto}

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:fecha_emision, :date)
    field(:dir_establecimiento, :string)
    field(:obligado_contabilidad, :string)
    field(:contribuyente_especial, :string)
    field(:tipo_identificacion_comprador, :integer)
    field(:razon_social_comprador, :string)
    field(:identificacion_comprador, :string)
    field(:direccion_comprador, :string)
    field(:total_sin_impuestos, :decimal)
    field(:total_descuento, :decimal)
    field(:propina, :decimal)
    field(:importe_total, :decimal)
    field(:moneda, :string)

    embeds_many(:total_con_impuestos, TotalImpuesto)
    embeds_many(:pagos, Pago)
  end

  def changeset(info_factura, params) do
    info_factura
    |> cast(params, [
      :fecha_emision,
      :dir_establecimiento,
      :obligado_contabilidad,
      :contribuyente_especial,
      :tipo_identificacion_comprador,
      :razon_social_comprador,
      :identificacion_comprador,
      :direccion_comprador,
      :total_sin_impuestos,
      :total_descuento,
      :propina,
      :importe_total,
      :moneda
    ])
    |> validate_required([
      :fecha_emision,
      :dir_establecimiento,
      :obligado_contabilidad,
      :tipo_identificacion_comprador,
      :razon_social_comprador,
      :identificacion_comprador,
      :total_sin_impuestos,
      :total_descuento,
      :propina,
      :importe_total,
      :moneda
    ])
    |> validate_length(:dir_establecimiento, max: 300)
    |> validate_inclusion(:obligado_contabilidad, ["SI", "NO"])
    |> validate_length(:contribuyente_especial, min: 3, max: 13)
    |> validate_number(:tipo_identificacion_comprador, greater_than_or_equal_to: 1, less_than: 100)
    |> validate_length(:razon_social_comprador, max: 300)
    |> validate_length(:identificacion_comprador, max: 13)
    |> validate_length(:direccion_comprador, max: 300)
    |> validate_length(:moneda, max: 15)
    |> cast_embed(:total_con_impuestos, required: true, with: &TotalImpuesto.changeset/2)
    |> cast_embed(:pagos, required: true, with: &Pago.changeset/2)
  end

  def to_doc(%BillingCore.Dataset.Factura.InfoFactura{} = info_factura, decimals \\ @decimals) do
    doc =
      [
        {:fechaEmision, nil, format_fecha_emision(info_factura.fecha_emision)},
        {:dirEstablecimiento, nil, info_factura.dir_establecimiento},
        {:obligadoContabilidad, nil, info_factura.obligado_contabilidad},
        {:tipoIdentificacionComprador, nil,
         info_factura.tipo_identificacion_comprador
         |> Integer.to_string()
         |> String.pad_leading(2, "0")},
        {:razonSocialComprador, nil, info_factura.razon_social_comprador},
        {:identificacionComprador, nil, info_factura.identificacion_comprador},
        {:direccionComprador, nil, info_factura.direccion_comprador},
        {:totalSinImpuestos, nil,
         Decimal.round(info_factura.total_sin_impuestos, decimals) |> Decimal.to_string(:normal)},
        {:totalDescuento, nil,
         Decimal.round(info_factura.total_descuento, decimals) |> Decimal.to_string(:normal)},
        {:totalConImpuestos, nil, total_con_impuestos_to_doc(info_factura.total_con_impuestos)},
        {:propina, nil, Decimal.round(info_factura.propina, decimals) |> Decimal.to_string(:normal)},
        {:importeTotal, nil,
         Decimal.round(info_factura.importe_total, decimals) |> Decimal.to_string(:normal)},
        {:moneda, nil, info_factura.moneda},
        {:pagos, nil, pagos_to_doc(info_factura.pagos)}
      ]
      |> add_contribuyente_especial(info_factura)

    {
      :infoFactura,
      nil,
      doc
    }
  end

  def to_xml(%BillingCore.Dataset.Factura.InfoFactura{} = info_factura) do
    to_doc(info_factura)
    |> XmlBuilder.generate()
  end

  defp total_con_impuestos_to_doc(total_con_impuestos) do
    total_con_impuestos
    |> Enum.map(fn impuesto -> TotalImpuesto.to_doc(impuesto) end)
  end

  defp pagos_to_doc(pagos) do
    pagos
    |> Enum.map(fn pago -> Pago.to_doc(:pago, pago) end)
  end

  defp format_fecha_emision(fecha_emision) do
    day = fecha_emision.day |> Integer.to_string() |> String.pad_leading(2, "0")
    month = fecha_emision.month |> Integer.to_string() |> String.pad_leading(2, "0")

    [day, month, fecha_emision.year] |> Enum.join("/")
  end

  defp add_contribuyente_especial(doc, %{
         obligado_contabilidad: "SI",
         contribuyente_especial: contribuyente_especial
       }) do
    List.insert_at(doc, 2, {:contribuyenteEspecial, nil, contribuyente_especial})
  end

  defp add_contribuyente_especial(doc, %{obligado_contabilidad: _}), do: doc
end
