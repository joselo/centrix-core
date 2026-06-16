defmodule CentrixCore.RetentionSandbox do
  def test_retention_sandbox do
    environment = 1
    retencion_params = get_retencion_params()
    p12_path = "test/fixtures/file.p12"
    p12_password = System.get_env("TEST_P12_FILE_PASSWORD")

    with {:ok, [xml: xml, clave_acceso: access_key]} <- CentrixCore.XmlRetentionBuilder.build_retention(retencion_params),
         {:ok, xml_signed} <- CentrixCore.Signing.sign(xml, p12_path, p12_password),
         {:ok, %{status: sri_status, response: response}} <- CentrixCore.SriClient.send_document(xml_signed, environment),
         {:ok, %{status: authorization_status, response: authorization_response}} <- CentrixCore.SriClient.is_authorized(access_key, environment) do

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

  def get_retencion_params() do
    %{
      info_tributaria: %{
        ambiente: 1,
        tipo_emision: 1,
        razon_social: "CARRION JUMBO JOSE AUGUSTO",
        nombre_comercial: "INITMAIN",
        ruc: "1103671804001",
        cod_doc: 7, # Comprobante de Retencion
        estab: 1,
        pto_emi: 100,
        secuencial: 33,
        dir_matriz: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        clave: %{
          fecha_emision: "2026-05-04",
          tipo_comprobante: 7,
          ruc: "1103671804001",
          ambiente: 1,
          estab: 1,
          pto_emi: 100,
          secuencial: 33,
          codigo: 1,
          tipo_emision: 1
        }
      },
      info_comp_retencion: %{
        fecha_emision: "2026-05-04",
        dir_establecimiento: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        obligado_contabilidad: "NO",
        tipo_identificacion_sujeto_retenido: "04",
        parte_rel: "NO",
        razon_social_sujeto_retenido: "Novaux Inc.",
        identificacion_sujeto_retenido: "465219513",
        periodo_fiscal: "05/2026"
      },
      docs_sustento: [
        %{
          cod_sustento: "01",
          cod_doc_sustento: "01",
          num_doc_sustento: "001100000000433",
          fecha_emision_doc_sustento: "2026-05-04",
          num_aut_doc_sustento: "0302202001110367180400110011000000000330000000110",
          pago_loc_ext: "01",
          total_sin_impuestos: 100.00,
          importe_total: 112.00,
          impuestos_doc_sustento: [
            %{
              cod_impuesto_doc_sustento: "2",
              codigo_porcentaje: "2",
              base_imponible: 100.00,
              tarifa: 12.00,
              valor_impuesto: 12.00
            }
          ],
          retenciones: [
            %{
              codigo: "1",
              codigo_retencion: "312",
              base_imponible: 100.00,
              porcentaje_retener: 1.75,
              valor_retenido: 1.75
            }
          ],
          pagos: [
            %{
              forma_pago: "01",
              total: 110.25
            }
          ]
        }
      ],
      info_adicional: [
        %{
          nombre: "Direccion",
          valor: "East 109 St - 6J Manhattan NY"
        },
        %{
          nombre: "Email",
          valor: "javier@saborpos.com"
        }
      ]
    }
  end
end
