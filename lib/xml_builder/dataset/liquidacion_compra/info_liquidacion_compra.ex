defmodule BillingCore.Dataset.LiquidacionCompra.InfoLiquidacionCompra do
  @moduledoc false

  @decimals BillingCore.decimals()

  alias BillingCore.Dataset.Factura.Pago
  alias BillingCore.Dataset.LiquidacionCompra.TotalImpuesto

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:fecha_emision, :date)
    field(:dir_establecimiento, :string)
    field(:obligado_contabilidad, :string)
    field(:contribuyente_especial, :string)
    field(:tipo_identificacion_proveedor, :string)
    field(:razon_social_proveedor, :string)
    field(:identificacion_proveedor, :string)
    field(:direccion_proveedor, :string)
    field(:total_sin_impuestos, :float)
    field(:total_descuento, :float)
    field(:cod_doc_reembolso, :string)
    field(:total_comprobantes_reembolso, :float)
    field(:total_base_imponible_reembolso, :float)
    field(:total_impuesto_reembolso, :float)
    field(:importe_total, :float)
    field(:moneda, :string, default: "DOLAR")

    embeds_many(:total_con_impuestos, TotalImpuesto)
    embeds_many(:pagos, Pago)
  end

  def changeset(info_liquidacion, params \\ %{}) do
    info_liquidacion
    |> cast(params, [
      :fecha_emision,
      :dir_establecimiento,
      :obligado_contabilidad,
      :contribuyente_especial,
      :tipo_identificacion_proveedor,
      :razon_social_proveedor,
      :identificacion_proveedor,
      :direccion_proveedor,
      :total_sin_impuestos,
      :total_descuento,
      :cod_doc_reembolso,
      :total_comprobantes_reembolso,
      :total_base_imponible_reembolso,
      :total_impuesto_reembolso,
      :importe_total,
      :moneda
    ])
    |> validate_required([
      :fecha_emision,
      :razon_social_proveedor,
      :identificacion_proveedor,
      :total_sin_impuestos,
      :importe_total,
      :moneda
    ])
    |> cast_embed(:total_con_impuestos, required: true, with: &TotalImpuesto.changeset/2)
    |> cast_embed(:pagos, required: true, with: &Pago.changeset/2)
  end

  def to_doc(%BillingCore.Dataset.LiquidacionCompra.InfoLiquidacionCompra{} = info) do
    doc =
      [
        {:fechaEmision, nil, format_fecha_emision(info.fecha_emision)}
      ]
      |> add_dir_establecimiento(info)
      |> add_contribuyente_especial(info)
      |> add_obligado_contabilidad(info)
      |> add_tipo_identificacion_proveedor(info)
      |> add_razon_social_proveedor(info)
      |> add_identificacion_proveedor(info)
      |> add_direccion_proveedor(info)
      |> add_total_sin_impuestos(info)
      |> add_total_descuento(info)
      |> add_cod_doc_reembolso(info)
      |> add_total_comprobantes_reembolso(info)
      |> add_total_base_imponible_reembolso(info)
      |> add_total_impuesto_reembolso(info)
      |> add_total_con_impuestos(info)
      |> add_importe_total(info)
      |> add_moneda(info)
      |> add_pagos(info)

    {
      :infoLiquidacionCompra,
      nil,
      doc
    }
  end

  def to_xml(%BillingCore.Dataset.LiquidacionCompra.InfoLiquidacionCompra{} = info) do
    to_doc(info)
    |> XmlBuilder.generate()
  end

  defp format_fecha_emision(%Date{} = fecha_emision) do
    Timex.format!(fecha_emision, "%d/%m/%Y", :strftime)
  end

  defp add_dir_establecimiento(doc, %{dir_establecimiento: nil}), do: doc

  defp add_dir_establecimiento(doc, %{dir_establecimiento: dir_establecimiento}) do
    doc ++ [{:dirEstablecimiento, nil, dir_establecimiento}]
  end

  defp add_contribuyente_especial(doc, %{contribuyente_especial: nil}), do: doc

  defp add_contribuyente_especial(doc, %{contribuyente_especial: contribuyente_especial}) do
    doc ++ [{:contribuyenteEspecial, nil, contribuyente_especial}]
  end

  defp add_obligado_contabilidad(doc, %{obligado_contabilidad: nil}), do: doc

  defp add_obligado_contabilidad(doc, %{obligado_contabilidad: obligado_contabilidad}) do
    doc ++ [{:obligadoContabilidad, nil, obligado_contabilidad}]
  end

  defp add_tipo_identificacion_proveedor(doc, %{tipo_identificacion_proveedor: nil}), do: doc

  defp add_tipo_identificacion_proveedor(doc, %{tipo_identificacion_proveedor: tipo}) do
    doc ++ [{:tipoIdentificacionProveedor, nil, tipo}]
  end

  defp add_razon_social_proveedor(doc, %{razon_social_proveedor: razon_social}) do
    doc ++ [{:razonSocialProveedor, nil, razon_social}]
  end

  defp add_identificacion_proveedor(doc, %{identificacion_proveedor: identificacion}) do
    doc ++ [{:identificacionProveedor, nil, identificacion}]
  end

  defp add_direccion_proveedor(doc, %{direccion_proveedor: nil}), do: doc

  defp add_direccion_proveedor(doc, %{direccion_proveedor: direccion}) do
    doc ++ [{:direccionProveedor, nil, direccion}]
  end

  defp add_total_sin_impuestos(doc, %{total_sin_impuestos: total_sin_impuestos}) do
    doc ++ [{:totalSinImpuestos, nil, :erlang.float_to_binary(total_sin_impuestos, decimals: @decimals)}]
  end

  defp add_total_descuento(doc, %{total_descuento: nil}), do: doc

  defp add_total_descuento(doc, %{total_descuento: total_descuento}) do
    doc ++ [{:totalDescuento, nil, :erlang.float_to_binary(total_descuento, decimals: @decimals)}]
  end

  defp add_cod_doc_reembolso(doc, %{cod_doc_reembolso: nil}), do: doc

  defp add_cod_doc_reembolso(doc, %{cod_doc_reembolso: cod_doc_reembolso}) do
    doc ++ [{:codDocReembolso, nil, cod_doc_reembolso}]
  end

  defp add_total_comprobantes_reembolso(doc, %{total_comprobantes_reembolso: nil}), do: doc

  defp add_total_comprobantes_reembolso(doc, %{total_comprobantes_reembolso: total_comprobantes_reembolso}) do
    doc ++ [{:totalComprobantesReembolso, nil, :erlang.float_to_binary(total_comprobantes_reembolso, decimals: @decimals)}]
  end

  defp add_total_base_imponible_reembolso(doc, %{total_base_imponible_reembolso: nil}), do: doc

  defp add_total_base_imponible_reembolso(doc, %{total_base_imponible_reembolso: total_base_imponible_reembolso}) do
    doc ++ [{:totalBaseImponibleReembolso, nil, :erlang.float_to_binary(total_base_imponible_reembolso, decimals: @decimals)}]
  end

  defp add_total_impuesto_reembolso(doc, %{total_impuesto_reembolso: nil}), do: doc

  defp add_total_impuesto_reembolso(doc, %{total_impuesto_reembolso: total_impuesto_reembolso}) do
    doc ++ [{:totalImpuestoReembolso, nil, :erlang.float_to_binary(total_impuesto_reembolso, decimals: @decimals)}]
  end

  defp add_total_con_impuestos(doc, %{total_con_impuestos: total_con_impuestos}) do
    impuestos_doc = Enum.map(total_con_impuestos, &TotalImpuesto.to_doc/1)
    doc ++ [{:totalConImpuestos, nil, impuestos_doc}]
  end

  defp add_importe_total(doc, %{importe_total: importe_total}) do
    doc ++ [{:importeTotal, nil, :erlang.float_to_binary(importe_total, decimals: @decimals)}]
  end

  defp add_moneda(doc, %{moneda: moneda}) do
    doc ++ [{:moneda, nil, moneda}]
  end

  defp add_pagos(doc, %{pagos: []}), do: doc

  defp add_pagos(doc, %{pagos: pagos}) do
    pagos_doc = Enum.map(pagos, fn pago -> Pago.to_doc(:pago, pago) end)
    doc ++ [{:pagos, nil, pagos_doc}]
  end
end
