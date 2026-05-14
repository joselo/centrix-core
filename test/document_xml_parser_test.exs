defmodule BillingCore.DocumentXmlParserTest do
  use ExUnit.Case
  alias BillingCore.DocumentXmlParser

  test "parse_xml with multiple payments in factura" do
    xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body>
        <ns2:autorizacionComprobanteResponse xmlns:ns2="http://ec.gob.sri.ws.autorizacion">
          <RespuestaAutorizacionComprobante>
            <autorizaciones>
              <autorizacion>
                <fechaAutorizacion>01/01/2024 10:00:00</fechaAutorizacion>
                <comprobante><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
    <factura id="comprobante" version="1.0.0">
      <infoTributaria>
        <ambiente>1</ambiente>
        <tipoEmision>1</tipoEmision>
        <razonSocial>EMPRESA PRUEBA</razonSocial>
        <nombreComercial>COMERCIAL PRUEBA</nombreComercial>
        <ruc>1234567890001</ruc>
        <claveAcceso>0101202401123456789000110010010000000011234567819</claveAcceso>
        <codDoc>01</codDoc>
        <estab>001</estab>
        <ptoEmi>001</ptoEmi>
        <secuencial>000000001</secuencial>
        <dirMatriz>DIRECCION MATRIZ</dirMatriz>
      </infoTributaria>
      <infoFactura>
        <fechaEmision>01/01/2024</fechaEmision>
        <dirEstablecimiento>DIRECCION SUCURSAL</dirEstablecimiento>
        <obligadoContabilidad>SI</obligadoContabilidad>
        <tipoIdentificacionComprador>05</tipoIdentificacionComprador>
        <razonSocialComprador>CLIENTE PRUEBA</razonSocialComprador>
        <identificacionComprador>9999999999</identificacionComprador>
        <totalSinImpuestos>10.00</totalSinImpuestos>
        <totalDescuento>0.00</totalDescuento>
        <totalConImpuestos>
          <totalImpuesto>
            <codigo>2</codigo>
            <codigoPorcentaje>2</codigoPorcentaje>
            <baseImponible>10.00</baseImponible>
            <valor>1.20</valor>
          </totalImpuesto>
        </totalConImpuestos>
        <importeTotal>11.20</importeTotal>
        <moneda>DOLAR</moneda>
        <pagos>
          <pago>
            <formaPago>01</formaPago>
            <total>5.00</total>
            <plazo>0</plazo>
            <unidadTiempo>Dias</unidadTiempo>
          </pago>
          <pago>
            <formaPago>19</formaPago>
            <total>6.20</total>
            <plazo>30</plazo>
            <unidadTiempo>Dias</unidadTiempo>
          </pago>
        </pagos>
      </infoFactura>
      <detalles>
        <detalle>
          <codigoPrincipal>P001</codigoPrincipal>
          <descripcion>PRODUCTO PRUEBA</descripcion>
          <cantidad>1</cantidad>
          <precioUnitario>10.00</precioUnitario>
          <descuento>0.00</descuento>
          <precioTotalSinImpuesto>10.00</precioTotalSinImpuesto>
        </detalle>
      </detalles>
    </factura>]]></comprobante>
              </autorizacion>
            </autorizaciones>
          </RespuestaAutorizacionComprobante>
        </ns2:autorizacionComprobanteResponse>
      </soap:Body>
    </soap:Envelope>
    """
    
    parsed = DocumentXmlParser.parse_xml(xml)
    assert length(parsed.document.payments) == 2
    assert Enum.at(parsed.document.payments, 0).total == Decimal.new("5.00")
    assert Enum.at(parsed.document.payments, 1).total == Decimal.new("6.20")
    assert Enum.at(parsed.document.payments, 1).method == "TARJETA DE CRÉDITO"
  end

  test "parse_xml with comprobanteRetencion" do
    xml_content = File.read!("test/fixtures/retencion/retencion.xml")
    # Wrap it in SOAP envelope for parse_xml
    xml = """
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body>
        <ns2:autorizacionComprobanteResponse xmlns:ns2="http://ec.gob.sri.ws.autorizacion">
          <RespuestaAutorizacionComprobante>
            <autorizaciones>
              <autorizacion>
                <fechaAutorizacion>04/05/2026 10:00:00</fechaAutorizacion>
                <comprobante><![CDATA[#{xml_content}]]></comprobante>
              </autorizacion>
            </autorizaciones>
          </RespuestaAutorizacionComprobante>
        </ns2:autorizacionComprobanteResponse>
      </soap:Body>
    </soap:Envelope>
    """

    parsed = DocumentXmlParser.parse_xml(xml)
    doc = parsed.document
    assert doc.root_tag == "comprobanteRetencion"
    assert doc.client_name == "Novaux Inc."
    assert doc.client_identification == "465219513"
    
    # Check items (retentions)
    # 1 retention in fixture
    assert length(doc.items) == 2 # Header + 1 item
    [_, item] = doc.items
    assert Enum.at(item, 0) == "001100000000433" # numDocSustento
    assert Enum.at(item, 7) == Decimal.new("1.75") # valorRetenido

    # Check payments
    assert length(doc.payments) == 1
    assert Enum.at(doc.payments, 0).total == Decimal.new("110.25")
    assert Enum.at(doc.payments, 0).method == "SIN UTILIZACION DEL SISTEMA FINANCIERO"
  end
end
