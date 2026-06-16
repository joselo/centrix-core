defmodule CentrixCore.Dataset.NotaCredito.TotalImpuestoTest do
  use ExUnit.Case

  alias CentrixCore.Dataset.NotaCredito.Test.FactorySupport
  alias CentrixCore.Dataset.NotaCredito.TotalImpuesto
  alias CentrixCore.Dataset.Test.XmlSupport

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
        {:baseImponible, nil, total_impuesto.base_imponible |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:valor, nil, total_impuesto.valor |> Decimal.round(2) |> Decimal.to_string(:normal)}
      ]
    }

    assert TotalImpuesto.to_doc(total_impuesto) == doc_expected
  end

  test "to_xml", %{total_impuesto: total_impuesto} do
    xml_expected =
      "test/fixtures/nota_credito/total_impuesto.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      total_impuesto
      |> TotalImpuesto.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
