defmodule BillingCore.Dataset.Factura.CampoAdicionalTest do
  use ExUnit.Case

  alias BillingCore.Dataset.Factura.CampoAdicional
  alias BillingCore.Dataset.Factura.Test.FactorySupport
  alias BillingCore.Dataset.Test.XmlSupport

  setup do
    campo_adicional = FactorySupport.campo_adicional_factory()

    {:ok, campo_adicional: campo_adicional}
  end

  test "new", %{campo_adicional: campo_adicional} do
    assert campo_adicional.nombre == "Direccion"
    assert campo_adicional.valor == "East 109 St - 6J Manhattan NY"
  end

  test "to_doc", %{campo_adicional: campo_adicional} do
    doc_expected = {
      :campoAdicional,
      %{nombre: campo_adicional.nombre},
      campo_adicional.valor
    }

    assert CampoAdicional.to_doc(campo_adicional) == doc_expected
  end

  test "to_xml", %{campo_adicional: campo_adicional} do
    xml_expected =
      "test/fixtures/campo_adicional.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      campo_adicional
      |> CampoAdicional.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
