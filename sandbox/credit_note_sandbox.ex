defmodule CentrixCore.CreditNoteSandbox do
  def test_credit_note_sandbox do
    environment = 1
    credit_note_params = get_credit_note_params()
    p12_path = "test/fixtures/file.p12"
    p12_password = System.get_env("TEST_P12_FILE_PASSWORD")

    with {:ok, [xml: xml, clave_acceso: access_key]} <- CentrixCore.XmlCreditNoteBuilder.build_credit_note(credit_note_params),
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

  defp get_credit_note_params do
    %{
      info_tributaria: %{
        ambiente: 1,
        tipo_emision: 1,
        razon_social: "CARRION JUMBO JOSE AUGUSTO",
        nombre_comercial: "INITMAIN",
        ruc: "1103671804001",
        cod_doc: 4, # 4=Nota de Compra
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
          fecha_emision: "2025-05-15",
          tipo_comprobante: 4 # 4=Nota de compra
        }
      },
      detalles: [
        %{
          descripcion: "SERVICIOS PROFESIONALES NOVAUX INC.",
          cantidad: 1.0,
          precio_unitario: 5.0,
          descuento: 0.0,
          precio_total_sin_impuesto: 5.0,
          detalles_adicionales: [
            %{valor: "desarrollo de software", nombre: "informacionAdicional"}
          ],
          impuestos: [
            %{
              codigo: 2,
              codigo_porcentaje: 0,
              base_imponible: 5.0,
              valor: 0.0,
              tarifa: 0.0
            }
          ],
          codigo_interno: "831410399",
          codigo_adicional: "2"
        }
      ],
      info_adicional: [
        %{valor: "East 109 St - 6J Manhattan NY", nombre: "Direccion"},
        %{valor: "javier@saborpos.com", nombre: "Email"}
      ],
      info_nota_credito: %{
        fecha_emision: "2025-05-15",
        dir_establecimiento: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        # obligado_contabilidad: "NO",
        tipo_identificacion_comprador: 8,
        razon_social_comprador: "Novaux Inc.",
        identificacion_comprador: "465219513",
        total_sin_impuestos: 5.0,
        total_con_impuestos: [
          %{codigo: 2, codigo_porcentaje: 0, base_imponible: 5.0, valor: 0.0}
        ],
        moneda: "DOLAR",
        cod_doc_modificado: "01", # 01=Factura
        num_doc_modificado: "001-100-000000433",
        fecha_emision_doc_sustento: "2025-05-15",
        valor_modificacion: 5.0,
        motivo: "NOTA DE CREDITO POR DEVOLUCION DE PRODUCTOS"
      }
    }
  end
end
