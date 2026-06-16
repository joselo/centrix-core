defmodule CentrixCore.Dataset.Factura.InfoTributariaTest do
  use ExUnit.Case

  alias CentrixCore.Dataset.Factura.InfoTributaria
  alias CentrixCore.Dataset.Factura.Test.FactorySupport
  alias CentrixCore.Dataset.Test.XmlSupport

  setup do
    info_tributaria = FactorySupport.info_tributaria_factory()

    {:ok, info_tributaria: info_tributaria}
  end

  test "test" do
    access_key_expected = "0302202001123456789000110010010000000010000000112"

    {:ok, fecha_emision} = Date.new(2020, 2, 3)

    clave_params = %{
      fecha_emision: fecha_emision,
      tipo_comprobante: 1,
      ruc: "1234567890001",
      ambiente: 1,
      estab: 1,
      pto_emi: 1,
      secuencial: 1,
      codigo: 1,
      tipo_emision: 1
    }

    params = %{
      ambiente: 1,
      tipo_emision: 1,
      razon_social: "TOMMY VERCETTI",
      nombre_comercial: "INITMAIN",
      ruc: "1111111111001",
      cod_doc: 1,
      estab: 1,
      pto_emi: 100,
      secuencial: 33,
      dir_matriz: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
      clave: clave_params
    }

    info_tributaria =
      %InfoTributaria{}
      |> InfoTributaria.changeset(params)
      |> Ecto.Changeset.apply_changes()

    assert info_tributaria.clave_acceso == access_key_expected
  end

  test "to_doc", %{info_tributaria: info_tributaria} do
    cod_doc = info_tributaria.cod_doc |> Integer.to_string() |> String.pad_leading(2, "0")
    estab = info_tributaria.estab |> Integer.to_string() |> String.pad_leading(3, "0")
    pto_emi = info_tributaria.pto_emi |> Integer.to_string() |> String.pad_leading(3, "0")
    secuencial = info_tributaria.secuencial |> Integer.to_string() |> String.pad_leading(9, "0")

    doc_expected = {
      :infoTributaria,
      nil,
      [
        {:ambiente, nil, info_tributaria.ambiente},
        {:tipoEmision, nil, info_tributaria.tipo_emision},
        {:razonSocial, nil, info_tributaria.razon_social},
        {:nombreComercial, nil, info_tributaria.nombre_comercial},
        {:ruc, nil, info_tributaria.ruc},
        {:claveAcceso, nil, info_tributaria.clave_acceso},
        {:codDoc, nil, cod_doc},
        {:estab, nil, estab},
        {:ptoEmi, nil, pto_emi},
        {:secuencial, nil, secuencial},
        {:dirMatriz, nil, info_tributaria.dir_matriz}
      ]
    }

    assert InfoTributaria.to_doc(info_tributaria) == doc_expected
  end

  test "to_xml", %{info_tributaria: info_tributaria} do
    xml_expected =
      "test/fixtures/info_tributaria.xml"
      |> File.read!()
      |> XmlSupport.format()

    xml =
      info_tributaria
      |> InfoTributaria.to_xml()
      |> XmlSupport.format()

    assert xml == xml_expected
  end
end
