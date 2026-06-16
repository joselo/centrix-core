defmodule CentrixCore.XmlRemissionGuideBuilderTest do
  use ExUnit.Case

  alias CentrixCore.XmlRemissionGuideBuilder

  describe "build_remission_guide/1" do
    test "build remission_guide and returns the xml and clave_acceso" do
      guia_remision_params = get_guia_remision_params()
      clave_acceso_expected = "0405202606110367180400110011000000000330000000118"

      assert {:ok, [xml: xml, clave_acceso: clave_acceso]} =
               XmlRemissionGuideBuilder.build_remission_guide(guia_remision_params)

      assert clave_acceso == clave_acceso_expected
      assert xml

      expected_xml =
        "test/fixtures/guia_remision/guia_remision.xml"
        |> Path.expand()
        |> File.read!()
        |> String.trim()

      assert String.replace(xml, ~r/\s/, "") == String.replace(expected_xml, ~r/\s/, "")
    end

    test "doesn't build the remission_guide and return errors" do
      assert {:error, _error} =
               XmlRemissionGuideBuilder.build_remission_guide(%{})
    end
  end

  def get_guia_remision_params do
    info_tributaria_params = %{
      ambiente: 1,
      tipo_emision: 1,
      razon_social: "CARRION JUMBO JOSE AUGUSTO",
      nombre_comercial: "INITMAIN",
      ruc: "1103671804001",
      cod_doc: 6,
      estab: 1,
      pto_emi: 100,
      secuencial: 33,
      dir_matriz: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
      clave: %{
        fecha_emision: "2026-05-04",
        tipo_comprobante: 6,
        ruc: "1103671804001",
        ambiente: 1,
        estab: 1,
        pto_emi: 100,
        secuencial: 33,
        codigo: 1,
        tipo_emision: 1
      }
    }

    info_guia_remision_params = %{
      dir_establecimiento: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
      dir_partida: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
      razon_social_transportista: "TRANSPORTE RAPIDO SA",
      tipo_identificacion_transportista: 4,
      ruc_transportista: "1792049504001",
      obligado_contabilidad: "NO",
      fecha_ini_transporte: "2026-05-04",
      fecha_fin_transporte: "2026-05-05",
      placa: "PCC-1234"
    }

    destinatarios_params = [
      %{
        identificacion_destinatario: "465219513",
        razon_social_destinatario: "Novaux Inc.",
        dir_destinatario: "East 109 St - 6J Manhattan NY",
        motivo_traslado: "Venta",
        cod_doc_sustento: "01",
        num_doc_sustento: "001-100-000000433",
        num_aut_doc_sustento: "0302202001110367180400110011000000000330000000110",
        fecha_emision_doc_sustento: "2026-05-04",
        detalles: [
          %{
            codigo_interno: "831410399",
            codigo_adicional: "2",
            descripcion: "SERVICIOS PROFESIONALES NOVAUX INC.",
            cantidad: 1.0,
            detalles_adicionales: [
              %{
                nombre: "informacionAdicional",
                valor: "desarrollo de software"
              }
            ]
          }
        ]
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
      info_guia_remision: info_guia_remision_params,
      destinatarios: destinatarios_params,
      info_adicional: info_adicional_params
    }
  end
end
