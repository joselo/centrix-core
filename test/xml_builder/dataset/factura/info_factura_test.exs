defmodule BillingCore.Dataset.Factura.InfoFacturaTest do
  use ExUnit.Case

  alias BillingCore.Dataset.Factura.{InfoFactura, Pago, TotalImpuesto}

  alias BillingCore.Dataset.Factura.Test.FactorySupport
  alias BillingCore.Dataset.Test.XmlSupport

  setup do
    info_factura = FactorySupport.info_factura_factory()
    info_factura_with_accounting = FactorySupport.info_factura_with_accounting_factory()

    {:ok, info_factura: info_factura, info_factura_with_accounting: info_factura_with_accounting}
  end

  test "to_doc without contribuyenteEspecial", %{info_factura: info_factura} do
    day = info_factura.fecha_emision.day |> Integer.to_string() |> String.pad_leading(2, "0")
    month = info_factura.fecha_emision.month |> Integer.to_string() |> String.pad_leading(2, "0")

    fecha_emision = [day, month, info_factura.fecha_emision.year] |> Enum.join("/")

    total_con_impuestos =
      info_factura.total_con_impuestos
      |> Enum.map(fn impuesto -> TotalImpuesto.to_doc(impuesto) end)

    pagos =
      info_factura.pagos
      |> Enum.map(fn pago -> Pago.to_doc(:pago, pago) end)

    doc_expected = {
      :infoFactura,
      nil,
      [
        {:fechaEmision, nil, fecha_emision},
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
         Decimal.round(info_factura.total_sin_impuestos, 2) |> Decimal.to_string(:normal)},
        {:totalDescuento, nil,
         Decimal.round(info_factura.total_descuento, 2) |> Decimal.to_string(:normal)},
        {:totalConImpuestos, nil, total_con_impuestos},
        {:propina, nil, Decimal.round(info_factura.propina, 2) |> Decimal.to_string(:normal)},
        {:importeTotal, nil, Decimal.round(info_factura.importe_total, 2) |> Decimal.to_string(:normal)},
        {:moneda, nil, info_factura.moneda},
        {:pagos, nil, pagos}
      ]
    }

    assert InfoFactura.to_doc(info_factura) == doc_expected
  end

  test "to_doc with contribuyenteEspecial", %{info_factura_with_accounting: info_factura} do
    day = info_factura.fecha_emision.day |> Integer.to_string() |> String.pad_leading(2, "0")
    month = info_factura.fecha_emision.month |> Integer.to_string() |> String.pad_leading(2, "0")

    fecha_emision = [day, month, info_factura.fecha_emision.year] |> Enum.join("/")

    total_con_impuestos =
      info_factura.total_con_impuestos
      |> Enum.map(fn impuesto -> TotalImpuesto.to_doc(impuesto) end)

    pagos =
      info_factura.pagos
      |> Enum.map(fn pago -> Pago.to_doc(:pago, pago) end)

    doc_expected = {
      :infoFactura,
      nil,
      [
        {:fechaEmision, nil, fecha_emision},
        {:dirEstablecimiento, nil, info_factura.dir_establecimiento},
        {:contribuyenteEspecial, nil, info_factura.contribuyente_especial},
        {:obligadoContabilidad, nil, info_factura.obligado_contabilidad},
        {:tipoIdentificacionComprador, nil,
         info_factura.tipo_identificacion_comprador
         |> Integer.to_string()
         |> String.pad_leading(2, "0")},
        {:razonSocialComprador, nil, info_factura.razon_social_comprador},
        {:identificacionComprador, nil, info_factura.identificacion_comprador},
        {:direccionComprador, nil, info_factura.direccion_comprador},
        {:totalSinImpuestos, nil,
         Decimal.round(info_factura.total_sin_impuestos, 2) |> Decimal.to_string(:normal)},
        {:totalDescuento, nil,
         Decimal.round(info_factura.total_descuento, 2) |> Decimal.to_string(:normal)},
        {:totalConImpuestos, nil, total_con_impuestos},
        {:propina, nil, Decimal.round(info_factura.propina, 2) |> Decimal.to_string(:normal)},
        {:importeTotal, nil, Decimal.round(info_factura.importe_total, 2) |> Decimal.to_string(:normal)},
        {:moneda, nil, info_factura.moneda},
        {:pagos, nil, pagos}
      ]
    }

    assert InfoFactura.to_doc(info_factura) == doc_expected
  end

  test "to_xml without contribuyenteEspecial", %{info_factura: info_factura} do
    xml_expected =
      File.read!("test/fixtures/info_factura.xml")
      |> XmlSupport.format()

    xml =
      InfoFactura.to_xml(info_factura)
      |> XmlSupport.format()

    assert xml == xml_expected
  end

  test "to_xml with contribuyenteEspecial", %{info_factura_with_accounting: info_factura} do
    xml_expected =
      File.read!("test/fixtures/info_factura_with_accounting.xml")
      |> XmlSupport.format()

    xml =
      InfoFactura.to_xml(info_factura)
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
