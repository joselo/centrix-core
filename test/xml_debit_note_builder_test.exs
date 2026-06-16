defmodule CentrixCore.XmlDebitNoteBuilderTest do
  use ExUnit.Case

  alias CentrixCore.XmlDebitNoteBuilder

  describe "build_debit_note/1" do
    test "build debit_note and returns the xml and clave_acceso" do
      nota_debito_params = get_nota_debito_params()
      clave_acceso_expected = "0302202005110367180400110011000000000330000000110"

      assert {:ok, [xml: xml, clave_acceso: clave_acceso]} =
               XmlDebitNoteBuilder.build_debit_note(nota_debito_params)

      assert clave_acceso == clave_acceso_expected
      assert xml

      expected_xml =
        "test/fixtures/nota_debito/nota_debito.xml"
        |> Path.expand()
        |> File.read!()
        |> String.trim()

      # Compara el XML generado ignorando diferencias de formato como espacios o saltos de línea
      assert String.replace(xml, ~r/\s/, "") == String.replace(expected_xml, ~r/\s/, "")
    end

    test "doesn't build the debit_note and return errors" do
      assert {:error, _error} =
               XmlDebitNoteBuilder.build_debit_note(%{})
    end
  end

  def get_nota_debito_params do
    info_tributaria_params = %{
      ambiente: 1,
      tipo_emision: 1,
      razon_social: "CARRION JUMBO JOSE AUGUSTO",
      nombre_comercial: "INITMAIN",
      ruc: "1103671804001",
      cod_doc: 5,
      estab: 1,
      pto_emi: 100,
      secuencial: 33,
      dir_matriz: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
      clave: %{
        fecha_emision: "2020-02-03",
        tipo_comprobante: 5,
        ruc: "1103671804001",
        ambiente: 1,
        estab: 1,
        pto_emi: 100,
        secuencial: 33,
        codigo: 1,
        tipo_emision: 1
      }
    }

    info_nota_debito_params = %{
      fecha_emision: "2020-02-03",
      dir_establecimiento: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
      tipo_identificacion_comprador: 4,
      razon_social_comprador: "Novaux Inc.",
      identificacion_comprador: "465219513",
      cod_doc_modificado: "01",
      num_doc_modificado: "001-001-112312315",
      fecha_emision_doc_sustento: "2020-02-03",
      total_sin_impuestos: 3000.00,
      valor_total: 3000.00,
      impuestos: [
        %{
          codigo: 2,
          codigo_porcentaje: 0,
          tarifa: 0.00,
          base_imponible: 3000.00,
          valor: 0.00
        }
      ],
      pagos: [
        %{
          forma_pago: 1,
          total: 3000.00,
          plazo: 30,
          unidad_tiempo: "dias"
        }
      ]
    }

    motivos_params = [
      %{
        razon: "Interés por mora",
        valor: 3000.00
      }
    ]

    info_adicional_params = [
      %{
        nombre: "Direccion",
        valor: "East 109 St - 6J Manhattan NY"
      },
      %{
        nombre: "Email",
        valor: "javier@saborpos.com"
      }
    ]

    %{
      info_tributaria: info_tributaria_params,
      info_nota_debito: info_nota_debito_params,
      motivos: motivos_params,
      info_adicional: info_adicional_params
    }
  end
end
