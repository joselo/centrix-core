defmodule CentrixCore.Dataset.NotaCredito.DetalleTest do
  use ExUnit.Case

  alias CentrixCore.Dataset.NotaCredito.DetAdicional
  alias CentrixCore.Dataset.NotaCredito.Detalle
  alias CentrixCore.Dataset.NotaCredito.Impuesto
  alias CentrixCore.Dataset.NotaCredito.Test.FactorySupport
  alias CentrixCore.Dataset.Test.XmlSupport

  setup do
    detalle = FactorySupport.detalle_factory()

    {:ok, detalle: detalle}
  end

  test "to_doc", %{detalle: detalle} do
    detalles_adicionales =
      Enum.map(detalle.detalles_adicionales, fn det_adicional -> DetAdicional.to_doc(det_adicional) end)

    impuestos =
      Enum.map(detalle.impuestos, fn impuesto -> Impuesto.to_doc(impuesto) end)

    doc_expected = {
      :detalle,
      nil,
      [
        {:codigoInterno, nil, detalle.codigo_interno},
        {:codigoAdicional, nil, detalle.codigo_adicional},
        {:descripcion, nil, detalle.descripcion},
        {:cantidad, nil, detalle.cantidad |> Decimal.round(6) |> Decimal.to_string(:normal)},
        {:precioUnitario, nil, detalle.precio_unitario |> Decimal.round(6) |> Decimal.to_string(:normal)},
        {:descuento, nil, detalle.descuento |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:precioTotalSinImpuesto, nil,
         detalle.precio_total_sin_impuesto |> Decimal.round(2) |> Decimal.to_string(:normal)},
        {:detallesAdicionales, nil, detalles_adicionales},
        {:impuestos, nil, impuestos}
      ]
    }

    assert Detalle.to_doc(detalle) == doc_expected
  end

  test "to_xml", %{detalle: detalle} do
    xml_expected =
      "test/fixtures/nota_credito/detalle.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      detalle
      |> Detalle.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
