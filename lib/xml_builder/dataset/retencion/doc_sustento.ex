defmodule BillingCore.Dataset.Retencion.DocSustento do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.Retencion.DocSustento
  alias BillingCore.Dataset.Retencion.ImpuestoDocSustento
  alias BillingCore.Dataset.Retencion.Pago
  alias BillingCore.Dataset.Retencion.Retencion

  @decimals BillingCore.decimals()

  embedded_schema do
    field(:cod_sustento, :string)
    field(:cod_doc_sustento, :string)
    field(:num_doc_sustento, :string)
    field(:fecha_emision_doc_sustento, :date)
    field(:fecha_registro_contable, :date)
    field(:num_aut_doc_sustento, :string)
    field(:pago_loc_ext, :string)
    field(:tipo_regi, :string)
    field(:pais_efec_pago, :string)
    field(:aplic_conv_dob_trib, :string)
    field(:pag_ext_suj_ret_nor_leg, :string)
    field(:pago_reg_fis, :string)
    field(:total_comprobantes_reembolso, :decimal)
    field(:total_base_imponible_reembolso, :decimal)
    field(:total_impuesto_reembolso, :decimal)
    field(:total_sin_impuestos, :decimal)
    field(:importe_total, :decimal)

    embeds_many(:impuestos_doc_sustento, ImpuestoDocSustento)
    embeds_many(:retenciones, Retencion)
    embeds_many(:pagos, Pago)
  end

  def changeset(doc_sustento, params \\ %{}) do
    doc_sustento
    |> cast(params, [
      :cod_sustento,
      :cod_doc_sustento,
      :num_doc_sustento,
      :fecha_emision_doc_sustento,
      :fecha_registro_contable,
      :num_aut_doc_sustento,
      :pago_loc_ext,
      :tipo_regi,
      :pais_efec_pago,
      :aplic_conv_dob_trib,
      :pag_ext_suj_ret_nor_leg,
      :pago_reg_fis,
      :total_comprobantes_reembolso,
      :total_base_imponible_reembolso,
      :total_impuesto_reembolso,
      :total_sin_impuestos,
      :importe_total
    ])
    |> clean_num_doc_sustento()
    |> validate_required([
      :cod_sustento,
      :cod_doc_sustento,
      :fecha_emision_doc_sustento,
      :total_sin_impuestos,
      :importe_total
    ])
    |> cast_embed(:impuestos_doc_sustento, with: &ImpuestoDocSustento.changeset/2)
    |> cast_embed(:retenciones, required: true, with: &Retencion.changeset/2)
    |> cast_embed(:pagos, required: true, with: &Pago.changeset/2)
  end

  defp clean_num_doc_sustento(changeset) do
    case get_change(changeset, :num_doc_sustento) do
      nil ->
        changeset

      number when is_binary(number) ->
        put_change(changeset, :num_doc_sustento, String.replace(number, "-", ""))
    end
  end

  def to_doc(%DocSustento{} = sustento) do
    doc =
      [
        {:codSustento, nil, sustento.cod_sustento},
        {:codDocSustento, nil, sustento.cod_doc_sustento}
      ]
      |> add_num_doc_sustento(sustento)
      |> add_fecha_emision_doc_sustento(sustento)
      |> add_fecha_registro_contable(sustento)
      |> add_num_aut_doc_sustento(sustento)
      |> add_pago_loc_ext(sustento)
      |> add_tipo_regi(sustento)
      |> add_pais_efec_pago(sustento)
      |> add_aplic_conv_dob_trib(sustento)
      |> add_pag_ext_suj_ret_nor_leg(sustento)
      |> add_pago_reg_fis(sustento)
      |> add_total_comprobantes_reembolso(sustento)
      |> add_total_base_imponible_reembolso(sustento)
      |> add_total_impuesto_reembolso(sustento)
      |> add_total_sin_impuestos(sustento)
      |> add_importe_total(sustento)
      |> add_impuestos_doc_sustento(sustento)
      |> add_retenciones(sustento)
      |> add_pagos(sustento)

    {
      :docSustento,
      nil,
      doc
    }
  end

  def to_xml(%DocSustento{} = sustento) do
    sustento
    |> to_doc()
    |> XmlBuilder.generate()
  end

  defp format_fecha_emision(%Date{} = fecha_emision) do
    Timex.format!(fecha_emision, "%d/%m/%Y", :strftime)
  end

  defp add_num_doc_sustento(doc, %{num_doc_sustento: nil}), do: doc

  defp add_num_doc_sustento(doc, %{num_doc_sustento: num_doc_sustento}) do
    doc ++ [{:numDocSustento, nil, num_doc_sustento}]
  end

  defp add_fecha_emision_doc_sustento(doc, %{fecha_emision_doc_sustento: nil}), do: doc

  defp add_fecha_emision_doc_sustento(doc, %{fecha_emision_doc_sustento: fecha_emision_doc_sustento}) do
    doc ++ [{:fechaEmisionDocSustento, nil, format_fecha_emision(fecha_emision_doc_sustento)}]
  end

  defp add_fecha_registro_contable(doc, %{fecha_registro_contable: nil}), do: doc

  defp add_fecha_registro_contable(doc, %{fecha_registro_contable: fecha_registro_contable}) do
    doc ++ [{:fechaRegistroContable, nil, format_fecha_emision(fecha_registro_contable)}]
  end

  defp add_num_aut_doc_sustento(doc, %{num_aut_doc_sustento: nil}), do: doc

  defp add_num_aut_doc_sustento(doc, %{num_aut_doc_sustento: num_aut_doc_sustento}) do
    doc ++ [{:numAutDocSustento, nil, num_aut_doc_sustento}]
  end

  defp add_pago_loc_ext(doc, %{pago_loc_ext: nil}), do: doc

  defp add_pago_loc_ext(doc, %{pago_loc_ext: pago_loc_ext}) do
    doc ++ [{:pagoLocExt, nil, pago_loc_ext}]
  end

  defp add_tipo_regi(doc, %{tipo_regi: nil}), do: doc

  defp add_tipo_regi(doc, %{tipo_regi: tipo_regi}) do
    doc ++ [{:tipoRegi, nil, tipo_regi}]
  end

  defp add_pais_efec_pago(doc, %{pais_efec_pago: nil}), do: doc

  defp add_pais_efec_pago(doc, %{pais_efec_pago: pais_efec_pago}) do
    doc ++ [{:paisEfecPago, nil, pais_efec_pago}]
  end

  defp add_aplic_conv_dob_trib(doc, %{aplic_conv_dob_trib: nil}), do: doc

  defp add_aplic_conv_dob_trib(doc, %{aplic_conv_dob_trib: aplic_conv_dob_trib}) do
    doc ++ [{:aplicConvDobTrib, nil, aplic_conv_dob_trib}]
  end

  defp add_pag_ext_suj_ret_nor_leg(doc, %{pag_ext_suj_ret_nor_leg: nil}), do: doc

  defp add_pag_ext_suj_ret_nor_leg(doc, %{pag_ext_suj_ret_nor_leg: pag_ext_suj_ret_nor_leg}) do
    doc ++ [{:pagExtSujRetNorLeg, nil, pag_ext_suj_ret_nor_leg}]
  end

  defp add_pago_reg_fis(doc, %{pago_reg_fis: nil}), do: doc

  defp add_pago_reg_fis(doc, %{pago_reg_fis: pago_reg_fis}) do
    doc ++ [{:pagoRegFis, nil, pago_reg_fis}]
  end

  defp add_total_comprobantes_reembolso(doc, %{total_comprobantes_reembolso: nil}), do: doc

  defp add_total_comprobantes_reembolso(doc, %{total_comprobantes_reembolso: total_comprobantes_reembolso}) do
    doc ++
      [
        {:totalComprobantesReembolso, nil,
         total_comprobantes_reembolso |> Decimal.round(@decimals) |> Decimal.to_string(:normal)}
      ]
  end

  defp add_total_base_imponible_reembolso(doc, %{total_base_imponible_reembolso: nil}), do: doc

  defp add_total_base_imponible_reembolso(doc, %{total_base_imponible_reembolso: total_base_imponible_reembolso}) do
    doc ++
      [
        {:totalBaseImponibleReembolso, nil,
         total_base_imponible_reembolso |> Decimal.round(@decimals) |> Decimal.to_string(:normal)}
      ]
  end

  defp add_total_impuesto_reembolso(doc, %{total_impuesto_reembolso: nil}), do: doc

  defp add_total_impuesto_reembolso(doc, %{total_impuesto_reembolso: total_impuesto_reembolso}) do
    doc ++
      [{:totalImpuestoReembolso, nil, total_impuesto_reembolso |> Decimal.round(@decimals) |> Decimal.to_string(:normal)}]
  end

  defp add_total_sin_impuestos(doc, %{total_sin_impuestos: total_sin_impuestos}) do
    doc ++ [{:totalSinImpuestos, nil, total_sin_impuestos |> Decimal.round(@decimals) |> Decimal.to_string(:normal)}]
  end

  defp add_importe_total(doc, %{importe_total: importe_total}) do
    doc ++ [{:importeTotal, nil, importe_total |> Decimal.round(@decimals) |> Decimal.to_string(:normal)}]
  end

  defp add_impuestos_doc_sustento(doc, %{impuestos_doc_sustento: []}), do: doc

  defp add_impuestos_doc_sustento(doc, %{impuestos_doc_sustento: impuestos_doc_sustento}) do
    impuestos_doc = Enum.map(impuestos_doc_sustento, &ImpuestoDocSustento.to_doc/1)
    doc ++ [{:impuestosDocSustento, nil, impuestos_doc}]
  end

  defp add_retenciones(doc, %{retenciones: []}), do: doc

  defp add_retenciones(doc, %{retenciones: retenciones}) do
    retenciones_doc = Enum.map(retenciones, &Retencion.to_doc/1)
    doc ++ [{:retenciones, nil, retenciones_doc}]
  end

  defp add_pagos(doc, %{pagos: []}), do: doc

  defp add_pagos(doc, %{pagos: pagos}) do
    pagos_doc = Enum.map(pagos, &Pago.to_doc/1)
    doc ++ [{:pagos, nil, pagos_doc}]
  end
end
