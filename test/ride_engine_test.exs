defmodule CentrixCore.RideEngineTest do
  use ExUnit.Case

  alias CentrixCore.DocumentXmlParser
  alias CentrixCore.RidePdfBuilder

  @nc_fixture "test/fixtures/nota_credito_authorized.xml"
  @invoice_fixture "test/fixtures/success_authorization_response.xml"

  test "DocumentXmlParser parses an authorized invoice correctly" do
    xml = File.read!(@invoice_fixture)
    parsed = DocumentXmlParser.parse_xml(xml)

    assert parsed.document.root_tag == "factura"
    assert parsed.document.cod_doc == "01"
    assert parsed.document.client_name == "The Doors"
    assert parsed.document.invoice_number == "001-001-796508085"
    # Header + 2 items
    assert length(parsed.document.items) == 3
  end

  test "DocumentXmlParser parses an authorized credit note correctly" do
    xml = File.read!(@nc_fixture)
    parsed = DocumentXmlParser.parse_xml(xml)

    assert parsed.document.root_tag == "notaCredito"
    assert parsed.document.cod_doc == "04"
    assert parsed.document.client_name == "The Doors"
    assert parsed.document.total == Decimal.new("11.20")
    assert parsed.document.modified_doc_number == "001-001-796508085"
    assert parsed.document.reason == "Devolución de mercadería"
  end

  test "RidePdfBuilder builds an invoice PDF" do
    xml = File.read!(@invoice_fixture)
    parsed = DocumentXmlParser.parse_xml(xml)

    pdf_binary = RidePdfBuilder.build(parsed)
    assert is_binary(pdf_binary)
    assert String.starts_with?(pdf_binary, "%PDF")
  end

  test "RidePdfBuilder builds a credit note PDF" do
    xml = File.read!(@nc_fixture)
    parsed = DocumentXmlParser.parse_xml(xml)

    pdf_binary = RidePdfBuilder.build(parsed)
    assert is_binary(pdf_binary)
    assert String.starts_with?(pdf_binary, "%PDF")
  end
end
