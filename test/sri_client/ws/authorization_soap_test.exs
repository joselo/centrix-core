defmodule BillingCore.AuthorizationSoapTest do
  use ExUnit.Case

  alias BillingCore.Dataset.Test.XmlSupport
  alias BillingCore.Ws

  setup do
    clave_acceso = "123456789"

    {:ok, clave_acceso: clave_acceso}
  end

  test "create_request/2", %{clave_acceso: clave_acceso} do
    xml_expected =
      "test/fixtures/verificar_comprobante.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      clave_acceso
      |> Ws.AuthorizationSoap.create_request(:autorizacionComprobante)
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
