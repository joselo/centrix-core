defmodule BillingCore.XmlPurchaseSettlementBuilderTest do
  use ExUnit.Case

  alias BillingCore.XmlPurchaseSettlementBuilder

  describe "build_purchase_settlement/1" do
    test "build purchase settlement and returns the xml and clave_acceso" do
      params = get_params()
      clave_acceso_expected = "0405202603110367180400110011000000000330000000119"

      assert {:ok, [xml: xml, clave_acceso: clave_acceso]} =
               XmlPurchaseSettlementBuilder.build_purchase_settlement(params)

      assert clave_acceso == clave_acceso_expected
      assert xml

      expected_xml =
        "test/fixtures/liquidacion_compra/liquidacion_compra.xml"
        |> Path.expand()
        |> File.read!()
        |> String.trim()

      assert String.replace(xml, ~r/\s/, "") == String.replace(expected_xml, ~r/\s/, "")
    end

    test "returns error if params are invalid" do
      assert {:error, _changeset} = XmlPurchaseSettlementBuilder.build_purchase_settlement(%{})
    end
  end

  defp get_params do
    %{
      info_tributaria: %{
        ambiente: 1,
        tipo_emision: 1,
        razon_social: "CARRION JUMBO JOSE AUGUSTO",
        nombre_comercial: "INITMAIN",
        ruc: "1103671804001",
        cod_doc: 3,
        estab: 1,
        pto_emi: 100,
        secuencial: 33,
        dir_matriz: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        clave: %{
          fecha_emision: "2026-05-04",
          tipo_comprobante: 3,
          ruc: "1103671804001",
          ambiente: 1,
          estab: 1,
          pto_emi: 100,
          secuencial: 33,
          codigo: 1,
          tipo_emision: 1
        }
      },
      info_liquidacion_compra: %{
        fecha_emision: "2026-05-04",
        dir_establecimiento:
          "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        obligado_contabilidad: "NO",
        tipo_identificacion_proveedor: "04",
        razon_social_proveedor: "Novaux Inc.",
        identificacion_proveedor: "1103671804001",
        direccion_proveedor: "East 109 St - 6J Manhattan NY",
        total_sin_impuestos: 100.00,
        total_descuento: 0.00,
        total_con_impuestos: [
          %{
            codigo: "2",
            codigo_porcentaje: "2",
            base_imponible: 100.00,
            tarifa: 12.00,
            valor: 12.00
          }
        ],
        importe_total: 112.00,
        moneda: "DOLAR",
        pagos: [
          %{
            forma_pago: 1,
            total: 112.00,
            plazo: 0,
            unidad_tiempo: "DIAS"
          }
        ]
      },
      detalles: [
        %{
          codigo_principal: "SERV-001",
          descripcion: "DESARROLLO DE SOFTWARE",
          unidad_medida: "HORA",
          cantidad: 1.0,
          precio_unitario: 100.0,
          descuento: 0.0,
          precio_total_sin_impuesto: 100.0,
          impuestos: [
            %{
              codigo: "2",
              codigo_porcentaje: "2",
              tarifa: 12.0,
              base_imponible: 100.0,
              valor: 12.0
            }
          ]
        }
      ],
      info_adicional: [
        %{
          nombre: "Email",
          valor: "javier@saborpos.com"
        }
      ]
    }
  end
end
