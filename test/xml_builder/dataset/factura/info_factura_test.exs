defmodule CentrixCore.Dataset.Factura.InfoFacturaTest do
  use ExUnit.Case

  alias CentrixCore.Dataset.Factura.InfoFactura
  alias CentrixCore.Dataset.Factura.Pago
  alias CentrixCore.Dataset.Factura.Test.FactorySupport
  alias CentrixCore.Dataset.Factura.TotalImpuesto
  alias CentrixCore.Dataset.Test.XmlSupport

  setup do
    info_factura = FactorySupport.info_factura_factory()
    info_factura_with_accounting = FactorySupport.info_factura_with_accounting_factory()

    {:ok, info_factura: info_factura, info_factura_with_accounting: info_factura_with_accounting}
  end

  test "to_doc without contribuyenteEspecial", %{info_factura: info_factura} do
    day = info_factura.fecha_emision.day |> Integer.to_string() |> String.pad_leading(2, "0")
    month = info_factura.fecha_emision.month |> Integer.to_string() |> String.pad_leading(2, "0")

    fecha_emision = Enum.join([day, month, info_factura.fecha_emision.year], "/")

    total_con_impuestos =
      Enum.map(info_factura.total_con_impuestos, fn impuesto -> TotalImpuesto.to_doc(impuesto) end)

    pagos =
      Enum.map(info_factura.pagos, fn pago -> Pago.to_doc(:pago, pago) end)

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
        {:totalSinImpuestos, nil, info_factura.total_sin_impuestos |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:totalDescuento, nil, info_factura.total_descuento |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:totalConImpuestos, nil, total_con_impuestos},
        {:propina, nil, info_factura.propina |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:importeTotal, nil, info_factura.importe_total |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:moneda, nil, info_factura.moneda},
        {:pagos, nil, pagos}
      ]
    }

    assert InfoFactura.to_doc(info_factura) == doc_expected
  end

  test "to_doc with contribuyenteEspecial", %{info_factura_with_accounting: info_factura} do
    day = info_factura.fecha_emision.day |> Integer.to_string() |> String.pad_leading(2, "0")
    month = info_factura.fecha_emision.month |> Integer.to_string() |> String.pad_leading(2, "0")

    fecha_emision = Enum.join([day, month, info_factura.fecha_emision.year], "/")

    total_con_impuestos =
      Enum.map(info_factura.total_con_impuestos, fn impuesto -> TotalImpuesto.to_doc(impuesto) end)

    pagos =
      Enum.map(info_factura.pagos, fn pago -> Pago.to_doc(:pago, pago) end)

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
        {:totalSinImpuestos, nil, info_factura.total_sin_impuestos |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:totalDescuento, nil, info_factura.total_descuento |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:totalConImpuestos, nil, total_con_impuestos},
        {:propina, nil, info_factura.propina |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:importeTotal, nil, info_factura.importe_total |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:moneda, nil, info_factura.moneda},
        {:pagos, nil, pagos}
      ]
    }

    assert InfoFactura.to_doc(info_factura) == doc_expected
  end

  test "to_xml without contribuyenteEspecial", %{info_factura: info_factura} do
    xml_expected =
      "test/fixtures/info_factura.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      info_factura
      |> InfoFactura.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end

  test "to_xml with contribuyenteEspecial", %{info_factura_with_accounting: info_factura} do
    xml_expected =
      "test/fixtures/info_factura_with_accounting.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      info_factura
      |> InfoFactura.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
