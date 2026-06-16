defmodule CentrixCore.InvoicePdfBuilderTest do
  use ExUnit.Case

  alias CentrixCore.InvoicePdfBuilder
  alias CentrixCore.InvoiceXmlParser

  setup do
    xml_file = File.read!("test/fixtures/success_authorization_response.xml")
    logo_path = "test/fixtures/logo.jpg"
    bar_code_path = "test/fixtures/logo.jpg"
    xml_parsed = InvoiceXmlParser.parse_xml(xml_file)

    {:ok, xml_parsed: xml_parsed, logo_path: logo_path, bar_code_path: bar_code_path}
  end

  describe "build/1" do
    test "build a pdf with logo_path and bar_code", %{
      xml_parsed: xml_parsed,
      logo_path: logo_path,
      bar_code_path: bar_code_path
    } do
      pdf = InvoicePdfBuilder.build(xml_parsed, logo_path, bar_code_path)
      File.write!("./tmp/invoice.pdf", pdf)
      File.rm("./tmp/invoice.pdf")
    end
  end
end
