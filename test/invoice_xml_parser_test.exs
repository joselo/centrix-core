defmodule BillingCore.InvoiceXmlParserTest do
  use ExUnit.Case

  alias BillingCore.InvoiceXmlParser

  setup do
    xml = File.read!("test/fixtures/success_authorization_response.xml")
    xml_map = XmlToMap.naive_map(xml)
    authorization = InvoiceXmlParser.get_authorization(xml_map)
    document = XmlToMap.naive_map(authorization["comprobante"])

    {:ok, xml_invoice: document}
  end

  test "get_items/1 returns 'detalles'", %{xml_invoice: xml_invoice} do
    expected = [
      [
        "Código",
        "Código Aux.",
        "Descripción",
        "Detalle Adic.",
        "Precio Unitario",
        "Cantidad",
        "Descuento",
        "Total"
      ],
      ["1", "1", "Metal Gear Solid V", "", Decimal.new("0.22"), Decimal.new("1.0"), Decimal.new("0.00"), Decimal.new("0.22")],
      ["1", "1", "Shipping", "", Decimal.new("2.50"), Decimal.new("1.0"), Decimal.new("0.00"), Decimal.new("2.50")]
    ]

    assert InvoiceXmlParser.get_items(xml_invoice) == expected
  end

  test "get_business_name/1 returns 'razonSocial'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_business_name(xml_invoice) == "TOMMY VERCETTI"
  end

  test "get_tradename/1 returns 'nombreComercial'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_tradename(xml_invoice) == "INITMAIN"
  end

  test "get_business_main_address/1 returns 'dirMatriz'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_business_main_address(xml_invoice) ==
             "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN"
  end

  test "get_business_branch_address/1 returns 'dirEstablecimiento'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_business_branch_address(xml_invoice) ==
             "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN"
  end

  test "get_accounting_number/1 returns 'contribuyenteEspecial'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_accounting_number(xml_invoice) == "666"
  end

  test "get_accounting/1 returns 'obligadoContabilidad'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_accounting(xml_invoice) == "SI"
  end

  test "get_business_identification/1 returns 'RUC'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_business_identification(xml_invoice) == "1111111111001"
  end

  test "get_client_name/1 returns 'razonSocialComprador'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_client_name(xml_invoice) == "The Doors"
  end

  test "get_client_identification/1 returns 'identificacionComprador'", %{
    xml_invoice: xml_invoice
  } do
    assert InvoiceXmlParser.get_client_identification(xml_invoice) == "1111111111"
  end

  test "get_client_address/1 returns 'direccionComprador'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_client_address(xml_invoice) == "The other side"
  end

  test "get_access_key/1 returns 'claveAcceso'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_access_key(xml_invoice) ==
             "0206202101111111111100110010017965080853956024310"
  end

  test "get_environment/1 returns 'ambiente'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_environment(xml_invoice) == "PRUEBAS"
  end

  test "get_emission_type/1 returns 'tipoEmision'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_emission_type(xml_invoice) == "NORMAL"
  end

  test "get_invoice_number/1 returns 'estab'-'ptoEmi'-'secuencial'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_invoice_number(xml_invoice) == "001-001-796508085"
  end

  test "get_client_fields/1 returns 'infoAdicional#first'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_client_fields(xml_invoice) == %{
             other_info: [%{name: "Correo electrónico", value: "jim@doors.com"}]
           }
  end

  test "get_payments/1 returns 'pagos#pago'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_payments(xml_invoice) == %{
             payments: [
               %{
                 due_date: "5 Dias",
                 method: "TARJETA DE CRÉDITO",
                 total: Decimal.new("3.05")
               }
             ]
           }
  end

  test "get_currency/1 returns 'moneda'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_currency(xml_invoice) == "DOLAR"
  end

  test "get_totals/1 returns 'totals'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_totals(xml_invoice) == %{
             sub_total_without_taxes: Decimal.new("2.72"),
             # total_without_taxes: "0.00",
             # total_with_taxes: "2.72",
             # total_taxes: "0.33",
             total_discount: Decimal.new("0.00"),
             total: Decimal.new("3.05")
           }
  end

  test "get_taxes/1 returns 'taxes'", %{xml_invoice: xml_invoice} do
    assert InvoiceXmlParser.get_taxes(xml_invoice) == [
             %{tax_value: Decimal.new("2.72"), tax_total: Decimal.new("0.33"), tax_code: "2", tax_label: "IVA 12%"},
             %{tax_value: Decimal.new("0.00"), tax_total: Decimal.new("0.00"), tax_code: "0", tax_label: "IVA 0%"}
           ]
  end

  test "returns nil if it cannot parse an xml without authorization" do
    xml = File.read!("test/fixtures/unauthorized_response_without_state.xml")

    assert !InvoiceXmlParser.parse_xml(xml)
  end
end
