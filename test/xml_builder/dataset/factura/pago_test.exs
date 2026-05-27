defmodule BillingCore.Dataset.Factura.PagoTest do
  use ExUnit.Case

  alias BillingCore.Dataset.Factura.Pago
  alias BillingCore.Dataset.Factura.Test.FactorySupport
  alias BillingCore.Dataset.Test.XmlSupport

  setup do
    pago = FactorySupport.pago_factory()

    {:ok, pago: pago}
  end

  test "to_doc", %{pago: pago} do
    doc_expected = {
      :pago,
      nil,
      [
        {:formaPago, nil, pago.forma_pago |> Integer.to_string() |> String.pad_leading(2, "0")},
        {:total, nil, pago.total |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:plazo, nil, pago.plazo},
        {:unidadTiempo, nil, pago.unidad_tiempo}
      ]
    }

    assert Pago.to_doc(:pago, pago) == doc_expected
  end

  test "to_xml", %{pago: pago} do
    xml_expected =
      "test/fixtures/pago.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      :pago
      |> Pago.to_xml(pago)
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
