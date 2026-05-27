defmodule BillingCore.Dataset.NotaCredito.DetAdicionalTest do
  use ExUnit.Case

  alias BillingCore.Dataset.NotaCredito.DetAdicional
  alias BillingCore.Dataset.NotaCredito.Test.FactorySupport
  alias BillingCore.Dataset.Test.XmlSupport

  setup do
    det_adicional = FactorySupport.det_adicional_factory()

    {:ok, det_adicional: det_adicional}
  end

  test "new", %{det_adicional: det_adicional} do
    assert det_adicional.nombre == "Unidad"
    assert det_adicional.valor == "UNIDAD"
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
      "test/fixtures/nota_credito/det_adicional.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      det_adicional
      |> DetAdicional.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
