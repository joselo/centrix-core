defmodule BillingCore.Dataset.Factura.DetAdicionalTest do
  use ExUnit.Case

  alias BillingCore.Dataset.Factura.DetAdicional

  alias BillingCore.Dataset.Factura.Test.FactorySupport
  alias BillingCore.Dataset.Test.XmlSupport

  setup do
    det_adicional = FactorySupport.det_adicional_factory()

    {:ok, det_adicional: det_adicional}
  end

  test "new", %{det_adicional: det_adicional} do
    assert det_adicional.nombre == "informacionAdicional"
    assert det_adicional.valor == "desarrollo de software"
  end

  test "to_doc", %{det_adicional: det_adicional} do
    doc_expected = {
      :detAdicional,
      [valor: det_adicional.valor, nombre: det_adicional.nombre],
      nil
    }

    assert DetAdicional.to_doc(det_adicional) == doc_expected
  end

  test "to_xml", %{det_adicional: det_adicional} do
    xml_expected =
      File.read!("test/fixtures/det_adicional.xml")
      |> XmlSupport.format()

    xml =
      DetAdicional.to_xml(det_adicional)
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
