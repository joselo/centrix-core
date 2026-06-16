defmodule CentrixCore.InvoiceSandbox do
  def test_invoice_sandbox do
    environment = 1
    invoice_params = get_invoice_params()
    p12_path = "test/fixtures/file.p12"
    p12_password = System.get_env("TEST_P12_FILE_PASSWORD")

    with {:ok, [xml: xml, clave_acceso: access_key]} <- CentrixCore.XmlBuilder.build_invoice(invoice_params),
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
    end
  end

  defp get_invoice_params do
    %{
      info_tributaria: %{
        ambiente: 1,
        tipo_emision: 1,
        razon_social: "CARRION JUMBO JOSE AUGUSTO",
        nombre_comercial: "INITMAIN",
        ruc: "1103671804001",
        cod_doc: 1,
        estab: 1,
        pto_emi: 100,
        secuencial: 433,
        dir_matriz: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        clave: %{
          ambiente: 1,
          tipo_emision: 1,
          ruc: "1103671804001",
          estab: 1,
          pto_emi: 100,
          secuencial: 433,
          codigo: 1,
          fecha_emision: "2025-05-15",
          tipo_comprobante: 1
        }
      },
      info_factura: %{
        fecha_emision: "2025-05-15",
        dir_establecimiento: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        obligado_contabilidad: "NO",
        tipo_identificacion_comprador: 8,
        razon_social_comprador: "Novaux Inc.",
        identificacion_comprador: "465219513",
        total_sin_impuestos: 5.0,
        total_descuento: 0.0,
        total_con_impuestos: [
          %{codigo: 2, codigo_porcentaje: 0, base_imponible: 5.0, valor: 0.0}
        ],
        propina: 0,
        importe_total: 5.0,
        moneda: "DOLAR",
        pagos: [%{total: 5.0, forma_pago: 20, plazo: 15, unidad_tiempo: "Dias"}]
      },
      detalles: [
        %{
          codigo_principal: "831410399",
          codigo_auxiliar: "2",
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
