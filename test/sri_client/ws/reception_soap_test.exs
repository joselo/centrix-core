defmodule CentrixCore.SoapTest do
  use ExUnit.Case

  alias CentrixCore.Dataset.Test.XmlSupport
  alias CentrixCore.Ws

  setup do
    xml = "<xml />"

    {:ok, xml: xml}
  end

  test "create_request/2", %{xml: xml} do
    xml_expected =
      "test/fixtures/validar_comprobante.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      xml
      |> Ws.ReceptionSoap.create_request(:validarComprobante)
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
