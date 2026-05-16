defmodule BillingCore.Dataset.Factura.ImpuestoTest do
  use ExUnit.Case

  alias BillingCore.Dataset.Factura.Impuesto

  alias BillingCore.Dataset.Factura.Test.FactorySupport
  alias BillingCore.Dataset.Test.XmlSupport

  setup do
    impuesto = FactorySupport.impuesto_factory()

    {:ok, impuesto: impuesto}
  end

  test "to_doc", %{impuesto: impuesto} do
    doc_expected = {
      :impuesto,
      nil,
      [
        {:codigo, nil, impuesto.codigo},
        {:codigoPorcentaje, nil, impuesto.codigo_porcentaje},
        {:tarifa, nil, Decimal.round(impuesto.tarifa, 2) |> Decimal.to_string(:normal)},
        {:baseImponible, nil, Decimal.round(impuesto.base_imponible, 2) |> Decimal.to_string(:normal)},
        {:valor, nil, Decimal.round(impuesto.valor, 2) |> Decimal.to_string(:normal)}
      ]
    }

    assert Impuesto.to_doc(impuesto) == doc_expected
  end

  test "to_xml", %{impuesto: impuesto} do
    xml_expected =
      File.read!("test/fixtures/impuesto.xml")
      |> XmlSupport.format()

    xml =
      Impuesto.to_xml(impuesto)
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
