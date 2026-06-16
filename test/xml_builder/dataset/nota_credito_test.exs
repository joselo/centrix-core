defmodule CentrixCore.Dataset.NotaCreditoTest do
  use ExUnit.Case

  alias CentrixCore.Dataset.NotaCredito
  alias CentrixCore.Dataset.NotaCredito.CampoAdicional
  alias CentrixCore.Dataset.NotaCredito.Detalle
  alias CentrixCore.Dataset.NotaCredito.InfoNotaCredito
  alias CentrixCore.Dataset.NotaCredito.InfoTributaria
  alias CentrixCore.Dataset.NotaCredito.Test.FactorySupport
  alias CentrixCore.Dataset.Test.XmlSupport

  setup do
    nota_credito = FactorySupport.nota_credito_factory()

    {:ok, nota_credito: nota_credito}
  end

  test "to_doc", %{nota_credito: nota_credito} do
    detalles =
      Enum.map(nota_credito.detalles, fn detalle -> Detalle.to_doc(detalle) end)

    info_adicional =
      Enum.map(nota_credito.info_adicional, fn info -> CampoAdicional.to_doc(info) end)

    doc_expected = {
      :notaCredito,
      %{id: "comprobante", version: "1.1.0"},
      [
        InfoTributaria.to_doc(nota_credito.info_tributaria),
        InfoNotaCredito.to_doc(nota_credito.info_nota_credito),
        {:detalles, nil, detalles},
        {:infoAdicional, nil, info_adicional}
      ]
    }

    assert NotaCredito.to_doc(nota_credito) == doc_expected
  end

  test "to_xml", %{nota_credito: nota_credito} do
    xml_expected =
      "test/fixtures/nota_credito/nota_credito.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      nota_credito
      |> NotaCredito.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
