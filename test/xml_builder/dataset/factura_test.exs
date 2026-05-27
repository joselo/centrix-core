defmodule BillingCore.Dataset.FacturaTest do
  use ExUnit.Case

  alias BillingCore.Dataset.Factura
  alias BillingCore.Dataset.Factura.CampoAdicional
  alias BillingCore.Dataset.Factura.Detalle
  alias BillingCore.Dataset.Factura.InfoFactura
  alias BillingCore.Dataset.Factura.InfoTributaria
  alias BillingCore.Dataset.Factura.Test.FactorySupport
  alias BillingCore.Dataset.Test.XmlSupport

  setup do
    factura = FactorySupport.factura_factory()

    {:ok, factura: factura}
  end

  test "to_doc", %{factura: factura} do
    detalles =
      Enum.map(factura.detalles, fn detalle -> Detalle.to_doc(detalle) end)

    info_adicional =
      Enum.map(factura.info_adicional, fn info -> CampoAdicional.to_doc(info) end)

    doc_expected = {
      :factura,
      %{id: "comprobante", version: "1.1.0"},
      [
        InfoTributaria.to_doc(factura.info_tributaria),
        InfoFactura.to_doc(factura.info_factura),
        {:detalles, nil, detalles},
        {:infoAdicional, nil, info_adicional}
      ]
    }

    assert Factura.to_doc(factura) == doc_expected
  end

  test "to_xml", %{factura: factura} do
    xml_expected =
      "test/fixtures/factura.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      factura
      |> Factura.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
