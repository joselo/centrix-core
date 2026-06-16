defmodule CentrixCore.Dataset.NotaCredito.Test.FactorySupport do
  @moduledoc false
  alias CentrixCore.Dataset.ClaveAcceso
  alias CentrixCore.Dataset.NotaCredito
  alias CentrixCore.Dataset.NotaCredito.CampoAdicional
  alias CentrixCore.Dataset.NotaCredito.DetAdicional
  alias CentrixCore.Dataset.NotaCredito.Detalle
  alias CentrixCore.Dataset.NotaCredito.Impuesto
  alias CentrixCore.Dataset.NotaCredito.InfoNotaCredito
  alias CentrixCore.Dataset.NotaCredito.InfoTributaria
  alias CentrixCore.Dataset.NotaCredito.TotalImpuesto

  def info_tributaria_factory do
    %InfoTributaria{
      ambiente: 2,
      tipo_emision: 1,
      razon_social: "ENRIQUE ULLAURI MATERIALES DE CONSTRUCCION CIA LTDA",
      nombre_comercial: "ENRIQUE ULLAURI CIA. LTDA.",
      ruc: "1191714098001",
      clave_acceso: "1603202304119171409800120011000000064601234567811",
      cod_doc: 4,
      estab: 1,
      pto_emi: 1,
      secuencial: 6460,
      dir_matriz: "BOLIVAR Y AV CATAMAYO",
      agente_retencion: 1
    }
  end

  def total_without_impuesto_factory do
    %TotalImpuesto{
      codigo: 2,
      codigo_porcentaje: 0,
      base_imponible: Decimal.new("0.0"),
      valor: Decimal.new("0.0")
    }
  end

  def total_impuesto_factory do
    %TotalImpuesto{
      codigo: 2,
      codigo_porcentaje: 2,
      base_imponible: Decimal.new("42.5"),
      valor: Decimal.new("5.1")
    }
  end

  def info_nota_credito_factory do
    {:ok, fecha_emision} = Date.new(2023, 3, 16)

    %InfoNotaCredito{
      fecha_emision: fecha_emision,
      dir_establecimiento: "BOLIVAR Y AV CATAMAYO",
      tipo_identificacion_comprador: 5,
      razon_social_comprador: "CARRION MORA LUIS",
      identificacion_comprador: 1_100_023_652,
      obligado_contabilidad: "NO",
      total_sin_impuestos: Decimal.new("42.5"),
      total_con_impuestos: [total_without_impuesto_factory(), total_impuesto_factory()],
      moneda: "DOLAR",
      cod_doc_modificado: "01",
      num_doc_modificado: "001-100-000246454",
      fecha_emision_doc_sustento: fecha_emision,
      valor_modificacion: Decimal.new("47.6"),
      motivo: "motivo0"
    }
  end

  def info_nota_credito_with_accounting_factory do
    struct!(
      info_nota_credito_factory(),
      %{
        obligado_contabilidad: "SI"
      }
    )
  end

  def det_adicional_factory do
    %DetAdicional{
      nombre: "Unidad",
      valor: "UNIDAD"
    }
  end

  def impuesto_factory do
    %Impuesto{
      codigo: 2,
      codigo_porcentaje: 2,
      tarifa: Decimal.new("12.0"),
      base_imponible: Decimal.new("42.5"),
      valor: Decimal.new("5.1")
    }
  end

  def detalle_factory do
    %Detalle{
      codigo_interno: "00005158",
      codigo_adicional: "00005158",
      descripcion: "SIKA EMPASTE EXTERIOR 20KG",
      cantidad: Decimal.new("2.0"),
      precio_unitario: Decimal.new("21.25"),
      descuento: Decimal.new("0.0"),
      precio_total_sin_impuesto: Decimal.new("42.5"),
      detalles_adicionales: [det_adicional_factory()],
      impuestos: [impuesto_factory()]
    }
  end

  def campo_adicional_factory do
    %CampoAdicional{
      nombre: "Direccion",
      valor: "East 109 St - 6J Manhattan NY"
    }
  end

  def campo_adicional_factory(nombre, valor) do
    %CampoAdicional{
      nombre: nombre,
      valor: valor
    }
  end

  def nota_credito_factory do
    campo_adicional1 = campo_adicional_factory("DIRECCION", "CALLE BOLIVAR Y ROSALES")
    campo_adicional2 = campo_adicional_factory("TELEFONO", "0960046802")
    campo_adicional3 = campo_adicional_factory("E-MAIL", "joseloc@gmail.com")

    campo_adicional4 =
      campo_adicional_factory("COMENTARIO", " POR CAMBIO\DEVOLUCION SE EMITIRA NC")

    campo_adicional5 = campo_adicional_factory("AGENTE DE RETENCION", "00000001")

    %NotaCredito{
      info_tributaria: info_tributaria_factory(),
      info_nota_credito: info_nota_credito_factory(),
      detalles: [detalle_factory()],
      info_adicional: [
        campo_adicional1,
        campo_adicional2,
        campo_adicional3,
        campo_adicional4,
        campo_adicional5
      ]
    }
  end

  def clave_factory do
    {:ok, fecha_emision} = Date.new(2023, 3, 16)

    %ClaveAcceso{
      fecha_emision: fecha_emision,
      tipo_comprobante: 4,
      ruc: "1191714098001",
      ambiente: 2,
      estab: 1,
      pto_emi: 100,
      secuencial: 6460,
      codigo: 1,
      tipo_emision: 4
    }
  end
end
