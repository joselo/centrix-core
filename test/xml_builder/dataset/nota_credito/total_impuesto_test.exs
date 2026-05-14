defmodule BillingCore.Dataset.NotaCredito.TotalImpuestoTest do
  use ExUnit.Case

  alias BillingCore.Dataset.NotaCredito.TotalImpuesto

  alias BillingCore.Dataset.NotaCredito.Test.FactorySupport
  alias BillingCore.Dataset.Test.XmlSupport

  setup do
    total_impuesto = FactorySupport.total_impuesto_factory()

    {:ok, total_impuesto: total_impuesto}
  end

  test "to_doc", %{total_impuesto: total_impuesto} do
    doc_expected = {
      :totalImpuesto,
      nil,
      [
        {:codigo, nil, total_impuesto.codigo},
        {:codigoPorcentaje, nil, total_impuesto.codigo_porcentaje},
        {:baseImponible, nil,
         Decimal.round(total_impuesto.base_imponible, 2) |> Decimal.to_string(:normal)},
        {:valor, nil, Decimal.round(total_impuesto.valor, 2) |> Decimal.to_string(:normal)}
      ]
    }

    assert TotalImpuesto.to_doc(total_impuesto) == doc_expected
  end

  test "to_xml", %{total_impuesto: total_impuesto} do
    xml_expected =
      File.read!("test/fixtures/nota_credito/total_impuesto.xml")
      |> XmlSupport.format()

    xml =
      TotalImpuesto.to_xml(total_impuesto)
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
