defmodule BillingCore.Dataset.NotaCredito.ImpuestoTest do
  use ExUnit.Case

  alias BillingCore.Dataset.NotaCredito.Impuesto
  alias BillingCore.Dataset.NotaCredito.Test.FactorySupport
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
        {:tarifa, nil, impuesto.tarifa |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:baseImponible, nil, impuesto.base_imponible |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:valor, nil, impuesto.valor |> Decimal.round(2) |> Decimal.to_string(:normal)}
      ]
    }

    assert Impuesto.to_doc(impuesto) == doc_expected
  end

  test "to_xml", %{impuesto: impuesto} do
    xml_expected =
      "test/fixtures/nota_credito/impuesto.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      impuesto
      |> Impuesto.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
