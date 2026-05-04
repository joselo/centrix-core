defmodule BillingCore.RemissionGuideSandbox do
  def test_remission_guide_sandbox do
    environment = 1
    guia_remision_params = get_guia_remision_params()
    p12_path = "test/fixtures/file.p12"
    p12_password = System.get_env("TEST_P12_FILE_PASSWORD")

    with {:ok, [xml: xml, clave_acceso: access_key]} <- BillingCore.XmlRemissionGuideBuilder.build_remission_guide(guia_remision_params),
         {:ok, xml_signed} <- BillingCore.Signing.sign(xml, p12_path, p12_password),
         {:ok, %{status: sri_status, response: response}} <- BillingCore.SriClient.send_document(xml_signed, environment),
         {:ok, %{status: authorization_status, response: authorization_response}} <- BillingCore.SriClient.is_authorized(access_key, environment) do

      IO.puts "Access Key:"
      IO.puts access_key

      IO.puts "--------------------"

      IO.puts "Sri Status"
      IO.puts sri_status

      IO.puts "--------------------"

      IO.puts "Response"
      IO.puts response

      IO.puts "--------------------"

      IO.puts "Auhorization Response"
      IO.puts authorization_status
      IO.puts authorization_response
    else
      error ->
        IO.inspect error
    end
  end

  defp get_guia_remision_params do
    %{
      info_tributaria: %{
        ambiente: 1,
        tipo_emision: 1,
        razon_social: "CARRION JUMBO JOSE AUGUSTO",
        nombre_comercial: "INITMAIN",
        ruc: "1103671804001",
        cod_doc: 6, # 6=Guia de remision
        estab: 1,
        pto_emi: 1,
        secuencial: 1,
        dir_matriz: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        clave: %{
          ambiente: 1,
          tipo_emision: 1,
          ruc: "1103671804001",
          estab: 1,
          pto_emi: 1,
          secuencial: 1,
          codigo: 1,
          fecha_emision: "2026-05-04",
          tipo_comprobante: 6 # 6=Guia de remision
        }
      },
      info_guia_remision: %{
        dir_establecimiento: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        dir_partida: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        razon_social_transportista: "TRANSPORTE RAPIDO SA",
        tipo_identificacion_transportista: "04",
        ruc_transportista: "1792049504001",
        obligado_contabilidad: "NO",
        fecha_ini_transporte: "2026-05-04",
        fecha_fin_transporte: "2026-05-05",
        placa: "PCC-1234"
      },
      destinatarios: [
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
      ],
      info_adicional: [
        %{valor: "East 109 St - 6J Manhattan NY", nombre: "Direccion"},
        %{valor: "javier@saborpos.com", nombre: "Email"}
      ]
    }
  end
end
