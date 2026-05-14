defmodule BillingCore.XmlCreditNoteBuilderTest do
  use ExUnit.Case

  alias BillingCore.XmlCreditNoteBuilder

  describe "build_credit_note/1" do
    test "build credit_note and starts the sign xml worker" do
      nota_credito_params = get_nota_credito_params()
      clave_acceso_expected = "0302202004123456789000110010010000000010000000111"

      assert {:ok, [xml: xml, clave_acceso: clave_acceso]} =
               XmlCreditNoteBuilder.build_credit_note(nota_credito_params)

      assert clave_acceso == clave_acceso_expected
      assert xml
    end

    test "doesn't build the credit_note and return errors" do
      assert {:error, _error} =
               XmlCreditNoteBuilder.build_credit_note(%{})
    end
  end

  def get_nota_credito_params(obligado_contabilidad \\ false) do
    accounting =
      if obligado_contabilidad do
        %{obligado_contabilidad: "SI", contribuyente_especial: "666"}
      else
        %{obligado_contabilidad: "NO"}
      end

    info_tributaria_params = %{
      ambiente: 1,
      tipo_emision: 1,
      razon_social: "CARRION JUMBO JOSE AUGUSTO",
      nombre_comercial: "INITMAIN",
      ruc: "1103671804001",
      cod_doc: 4,
      estab: 1,
      pto_emi: 100,
      secuencial: 33,
      dir_matriz: "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
      clave: %{
        fecha_emision: "2020-02-03",
        tipo_comprobante: 4,
        ruc: "1234567890001",
        ambiente: 1,
        estab: 1,
        pto_emi: 1,
        secuencial: 1,
        codigo: 1,
        tipo_emision: 1
      }
    }

    info_nota_credito_params =
      %{
        fecha_emision: "2020-02-03",
        dir_establecimiento:
          "Ciudadela: DAMMER II Calle: N49C Número: EC-102 Intersección: EL MORLAN",
        tipo_identificacion_comprador: 8,
        razon_social_comprador: "Novaux Inc.",
        identificacion_comprador: "465219513",
        total_sin_impuestos: 3000.00,
        obligado_contabilidad: "NO",
        rise: "rise0",
        cod_doc_modificado: "01",
        num_doc_modificado: "001001000000001",
        fecha_emision_doc_sustento: "2020-02-03",
        valor_modificacion: 3000.00,
        moneda: "DOLAR",
        motivo: "motivo0",
        total_con_impuestos: [
          %{
            codigo: 2,
            codigo_porcentaje: 0,
            base_imponible: 3000.00,
            valor: 0.00
          }
        ]
      }
      |> Map.merge(accounting)

    detalles_params = [
      %{
        codigo_interno: "831410399",
        codigo_adicional: "2",
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
      info_nota_credito: info_nota_credito_params,
      detalles: detalles_params,
      info_adicional: info_adicional_params
    }
  end
end
