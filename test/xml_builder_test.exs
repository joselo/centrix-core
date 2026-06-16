defmodule CentrixCore.XmlBuilderTest do
  use ExUnit.Case

  alias CentrixCore.XmlBuilder

  describe "build_invoice/1" do
    test "build invoice and starts the sign xml worker" do
      factura_params = get_factura_params()
      clave_acceso_expected = "0302202001123456789000110010010000000010000000112"

      assert {:ok, [xml: xml, clave_acceso: clave_acceso]} =
               XmlBuilder.build_invoice(factura_params)

      assert clave_acceso == clave_acceso_expected
      assert xml
    end

    test "doesn't build the invoice and return errors" do
      assert {:error, _error} =
               XmlBuilder.build_invoice(%{})
    end
  end

  def get_factura_params(obligado_contabilidad \\ false) do
    accounting =
      if obligado_contabilidad do
        %{obligado_contabilidad: "SI", contribuyente_especial: "666"}
      else
        %{obligado_contabilidad: "NO"}
      end

    info_tributaria_params = %{
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
      clave: %{
        fecha_emision: "2020-02-03",
        tipo_comprobante: 1,
        ruc: "1234567890001",
        ambiente: 1,
        estab: 1,
        pto_emi: 1,
        secuencial: 1,
        codigo: 1,
        tipo_emision: 1
      }
    }

    info_factura_params =
      Map.merge(
        %{
          fecha_emision: "2020-02-03",
          dir_establecimiento: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
          tipo_identificacion_comprador: 8,
          razon_social_comprador: "Novaux Inc.",
          identificacion_comprador: "465219513",
          total_sin_impuestos: 3000.00,
          total_descuento: 0.00,
          total_con_impuestos: [%{codigo: 2, codigo_porcentaje: 0, base_imponible: 3000.00, valor: 0.00}],
          propina: 0,
          importe_total: 3000.00,
          moneda: "DOLAR",
          pagos: [%{forma_pago: 20, total: 3000.00, plazo: 15, unidad_tiempo: "Dias"}]
        },
        accounting
      )

    detalles_params = [
      %{
        codigo_principal: "831410399",
        codigo_auxiliar: "2",
        descripcion: "SERVICIOS PROFESIONALES NOVAUX INC.",
        cantidad: 1.0,
        precio_unitario: 3000,
        descuento: 0.00,
        precio_total_sin_impuesto: 3000.00,
        detalles_adicionales: [
          %{
            nombre: "informacionAdicional",
            valor: "desarrollo de software"
          }
        ],
        impuestos: [
          %{
            codigo: 2,
            codigo_porcentaje: 0,
            tarifa: 0.00,
            base_imponible: 3000.00,
            valor: 0.00
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
      info_factura: info_factura_params,
      detalles: detalles_params,
      info_adicional: info_adicional_params
    }
  end
end
