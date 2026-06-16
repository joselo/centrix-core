defmodule CentrixCore.Dataset.NotaCredito.InfoNotaCreditoTest do
  use ExUnit.Case

  alias CentrixCore.Dataset.NotaCredito.InfoNotaCredito
  alias CentrixCore.Dataset.NotaCredito.Test.FactorySupport
  alias CentrixCore.Dataset.NotaCredito.TotalImpuesto
  alias CentrixCore.Dataset.Test.XmlSupport

  setup do
    info_nota_credito = FactorySupport.info_nota_credito_factory()
    info_nota_credito_with_accounting = FactorySupport.info_nota_credito_with_accounting_factory()

    {:ok, info_nota_credito: info_nota_credito, info_nota_credito_with_accounting: info_nota_credito_with_accounting}
  end

  test "to_doc without contribuyenteEspecial", %{info_nota_credito: info_nota_credito} do
    day = info_nota_credito.fecha_emision.day |> Integer.to_string() |> String.pad_leading(2, "0")

    month =
      info_nota_credito.fecha_emision.month |> Integer.to_string() |> String.pad_leading(2, "0")

    fecha_emision = Enum.join([day, month, info_nota_credito.fecha_emision.year], "/")

    fecha_emision_doc_sustento = Enum.join([day, month, info_nota_credito.fecha_emision_doc_sustento.year], "/")

    total_con_impuestos =
      Enum.map(info_nota_credito.total_con_impuestos, fn impuesto -> TotalImpuesto.to_doc(impuesto) end)

    doc_expected = {
      :infoNotaCredito,
      nil,
      [
        {:fechaEmision, nil, fecha_emision},
        {:dirEstablecimiento, nil, info_nota_credito.dir_establecimiento},
        {:tipoIdentificacionComprador, nil,
         info_nota_credito.tipo_identificacion_comprador
         |> Integer.to_string()
         |> String.pad_leading(2, "0")},
        {:razonSocialComprador, nil, info_nota_credito.razon_social_comprador},
        {:identificacionComprador, nil, info_nota_credito.identificacion_comprador},
        {:codDocModificado, nil, info_nota_credito.cod_doc_modificado},
        {:numDocModificado, nil, info_nota_credito.num_doc_modificado},
        {:fechaEmisionDocSustento, nil, fecha_emision_doc_sustento},
        {:totalSinImpuestos, nil,
         info_nota_credito.total_sin_impuestos |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:valorModificacion, nil, info_nota_credito.valor_modificacion |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:moneda, nil, info_nota_credito.moneda},
        {:totalConImpuestos, nil, total_con_impuestos},
        {:motivo, nil, info_nota_credito.motivo}
      ]
    }

    assert InfoNotaCredito.to_doc(info_nota_credito) == doc_expected
  end

  test "to_doc with contribuyenteEspecial", %{
    info_nota_credito_with_accounting: info_nota_credito
  } do
    day = info_nota_credito.fecha_emision.day |> Integer.to_string() |> String.pad_leading(2, "0")

    month =
      info_nota_credito.fecha_emision.month |> Integer.to_string() |> String.pad_leading(2, "0")

    fecha_emision = Enum.join([day, month, info_nota_credito.fecha_emision.year], "/")

    fecha_emision_doc_sustento = Enum.join([day, month, info_nota_credito.fecha_emision_doc_sustento.year], "/")

    total_con_impuestos =
      Enum.map(info_nota_credito.total_con_impuestos, fn impuesto -> TotalImpuesto.to_doc(impuesto) end)

    doc_expected = {
      :infoNotaCredito,
      nil,
      [
        {:fechaEmision, nil, fecha_emision},
        {:dirEstablecimiento, nil, info_nota_credito.dir_establecimiento},
        {:obligadoContabilidad, nil, info_nota_credito.obligado_contabilidad},
        {:tipoIdentificacionComprador, nil,
         info_nota_credito.tipo_identificacion_comprador
         |> Integer.to_string()
         |> String.pad_leading(2, "0")},
        {:razonSocialComprador, nil, info_nota_credito.razon_social_comprador},
        {:identificacionComprador, nil, info_nota_credito.identificacion_comprador},
        {:codDocModificado, nil, info_nota_credito.cod_doc_modificado},
        {:numDocModificado, nil, info_nota_credito.num_doc_modificado},
        {:fechaEmisionDocSustento, nil, fecha_emision_doc_sustento},
        {:totalSinImpuestos, nil,
         info_nota_credito.total_sin_impuestos |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:valorModificacion, nil, info_nota_credito.valor_modificacion |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:moneda, nil, info_nota_credito.moneda},
        {:totalConImpuestos, nil, total_con_impuestos},
        {:motivo, nil, info_nota_credito.motivo}
      ]
    }

    assert InfoNotaCredito.to_doc(info_nota_credito) == doc_expected
  end

  test "to_xml without contribuyenteEspecial", %{info_nota_credito: info_nota_credito} do
    xml_expected =
      "test/fixtures/nota_credito/info_nota_credito.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      info_nota_credito
      |> InfoNotaCredito.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end

  test "to_xml with contribuyenteEspecial", %{
    info_nota_credito_with_accounting: info_nota_credito
  } do
    xml_expected =
      "test/fixtures/nota_credito/info_nota_credito_with_accounting.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      info_nota_credito
      |> InfoNotaCredito.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
