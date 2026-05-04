defmodule BillingCore.DebitNoteSandbox do
  def test_debit_note_sandbox do
    environment = 1
    debit_note_params = get_debit_note_params()
    p12_path = "test/fixtures/file.p12"
    p12_password = System.get_env("TEST_P12_FILE_PASSWORD")

    with {:ok, [xml: xml, clave_acceso: access_key]} <- BillingCore.XmlDebitNoteBuilder.build_debit_note(debit_note_params),
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

  defp get_debit_note_params do
    %{
      info_tributaria: %{
        ambiente: 1,
        tipo_emision: 1,
        razon_social: "CARRION JUMBO JOSE AUGUSTO",
        nombre_comercial: "INITMAIN",
        ruc: "1103671804001",
        cod_doc: 5, # 5=Nota de Debito
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
          tipo_comprobante: 5 # 5=Nota de debito
        }
      },
      info_nota_debito: %{
        fecha_emision: "2026-05-04",
        dir_establecimiento: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        tipo_identificacion_comprador: "04",
        razon_social_comprador: "Novaux Inc.",
        identificacion_comprador: "465219513",
        cod_doc_modificado: "01",
        num_doc_modificado: "001-100-000000433",
        fecha_emision_doc_sustento: "2026-05-04",
        total_sin_impuestos: 10.0,
        valor_total: 10.0,
        impuestos: [
          %{
            codigo: 2,
            codigo_porcentaje: 0,
            tarifa: 0.0,
            base_imponible: 10.0,
            valor: 0.0
          }
        ],
        pagos: [
          %{
            forma_pago: 1,
            total: 10.0,
            plazo: 30,
            unidad_tiempo: "dias"
          }
        ]
      },
      motivos: [
        %{
          razon: "Intereses por mora",
          valor: 10.0
        }
      ],
      info_adicional: [
        %{valor: "East 109 St - 6J Manhattan NY", nombre: "Direccion"},
        %{valor: "javier@saborpos.com", nombre: "Email"}
      ]
    }
  end
end
