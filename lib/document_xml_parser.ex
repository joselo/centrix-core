defmodule BillingCore.DocumentXmlParser do
  @moduledoc """
  Generic SRI Document XML Parser.
  Supports Factura (01), Nota de Crédito (04) and others.
  """

  @headers [
    "Código",
    "Código Aux.",
    "Descripción",
    "Detalle Adic.",
    "Precio Unitario",
    "Cantidad",
    "Descuento",
    "Total"
  ]

  def parse_xml(nil), do: nil

  def parse_xml(xml) do
    xml_map = XmlToMap.naive_map(xml)
    authorization = get_authorization(xml_map)

    if authorization do
      comprobante_xml = authorization["comprobante"]
      document = parse(XmlToMap.naive_map(comprobante_xml))

      %{
        document: document,
        authorization_date: authorization["fechaAutorizacion"]
      }
    end
  end

  def get_authorization(xml_map) do
    xml_map["soap:Envelope"]["soap:Body"]["ns2:autorizacionComprobanteResponse"][
      "RespuestaAutorizacionComprobante"
    ]["autorizaciones"]["autorizacion"]
  end

  def parse(nil), do: nil

  def parse(xml_struct) do
    root_tag = find_root_tag(xml_struct)
    content = xml_struct[root_tag]["#content"]
    info_tributaria = content["infoTributaria"]

    # Detect document type specific block
    info_block_key =
      case root_tag do
        "factura" -> "infoFactura"
        "notaCredito" -> "infoNotaCredito"
        "notaDebito" -> "infoNotaDebito"
        "comprobanteRetencion" -> "infoCompRetencion"
        "guiaRemision" -> "infoGuiaRemision"
        "liquidacionCompra" -> "infoLiquidacionCompra"
        _ -> nil
      end

    info_block = content[info_block_key]

    base_data = %{
      root_tag: root_tag,
      cod_doc: info_tributaria["codDoc"],
      business_name: info_tributaria["razonSocial"],
      tradename: info_tributaria["nombreComercial"],
      business_identification: info_tributaria["ruc"],
      access_key: info_tributaria["claveAcceso"],
      environment: decode_environment(info_tributaria["ambiente"]),
      emssion_type: decode_emission_type(info_tributaria["tipoEmision"]),
      invoice_number: format_doc_number(info_tributaria),
      business_main_address: truncate_address(info_tributaria["dirMatriz"]),
      business_branch_address: truncate_address(info_block["dirEstablecimiento"]),
      accounting: info_block["obligadoContabilidad"],
      accounting_number: info_block["contribuyenteEspecial"],
      currency: info_block["moneda"] || "DOLAR",
      other_info: get_additional_info(content),
      items: get_items(content, root_tag)
    }

    # Merge specific data based on document type
    Map.merge(base_data, parse_specific_data(root_tag, info_block, content))
  end

  def find_root_tag(xml_struct) do
    Enum.find(
      [
        "factura",
        "notaCredito",
        "notaDebito",
        "comprobanteRetencion",
        "guiaRemision",
        "liquidacionCompra"
      ],
      fn tag -> Map.has_key?(xml_struct, tag) end
    )
  end

  def get_info_block_key(root_tag) do
    case root_tag do
      "factura" -> "infoFactura"
      "notaCredito" -> "infoNotaCredito"
      "notaDebito" -> "infoNotaDebito"
      "comprobanteRetencion" -> "infoCompRetencion"
      "guiaRemision" -> "infoGuiaRemision"
      "liquidacionCompra" -> "infoLiquidacionCompra"
      _ -> nil
    end
  end

  def parse_specific_data("factura", info_factura, _content) do
    %{
      client_name: info_factura["razonSocialComprador"],
      client_identification: info_factura["identificacionComprador"],
      client_address: info_factura["direccionComprador"],
      sub_total_without_taxes: Decimal.new(info_factura["totalSinImpuestos"] || "0"),
      total_discount: Decimal.new(info_factura["totalDescuento"] || "0"),
      total: Decimal.new(info_factura["importeTotal"] || "0"),
      taxes: get_taxes(info_factura),
      payments: get_payments(info_factura)
    }
  end

  def parse_specific_data("notaCredito", info_nc, _content) do
    %{
      client_name: info_nc["razonSocialComprador"],
      client_identification: info_nc["identificacionComprador"],
      client_address: info_nc["direccionComprador"],
      sub_total_without_taxes: Decimal.new(info_nc["totalSinImpuestos"] || "0"),
      total_discount: Decimal.new(info_nc["totalDescuento"] || "0"),
      total: Decimal.new(info_nc["valorModificacion"] || "0"),
      taxes: get_taxes(info_nc),
      # NC Specifics
      modified_doc_type: info_nc["codDocModificado"],
      modified_doc_number: info_nc["numDocModificado"],
      modified_doc_date: info_nc["fechaEmisionDocSustento"],
      reason: info_nc["motivo"]
    }
  end

  def parse_specific_data("notaDebito", info_nd, _content) do
    %{
      client_name: info_nd["razonSocialComprador"],
      client_identification: info_nd["identificacionComprador"],
      client_address: info_nd["direccionComprador"],
      sub_total_without_taxes: Decimal.new(info_nd["totalSinImpuestos"] || "0"),
      total_discount: Decimal.new("0.00"),
      total: Decimal.new(info_nd["valorTotal"] || "0"),
      taxes: get_nd_taxes(info_nd),
      payments: get_payments(info_nd),
      # ND Specifics
      modified_doc_type: info_nd["codDocModificado"],
      modified_doc_number: info_nd["numDocModificado"],
      modified_doc_date: info_nd["fechaEmisionDocSustento"]
    }
  end

  def parse_specific_data("guiaRemision", info_gr, _content) do
    %{
      client_name: info_gr["razonSocialTransportista"],
      client_identification: info_gr["rucTransportista"],
      client_address: info_gr["dirPartida"],
      sub_total_without_taxes: Decimal.new("0.00"),
      total_discount: Decimal.new("0.00"),
      total: Decimal.new("0.00"),
      taxes: [],
      payments: []
    }
  end

  def parse_specific_data("liquidacionCompra", info_lc, _content) do
    %{
      client_name: info_lc["razonSocialProveedor"],
      client_identification: info_lc["identificacionProveedor"],
      client_address: info_lc["direccionProveedor"],
      sub_total_without_taxes: Decimal.new(info_lc["totalSinImpuestos"] || "0"),
      total_discount: Decimal.new(info_lc["totalDescuento"] || "0"),
      total: Decimal.new(info_lc["importeTotal"] || "0"),
      taxes: get_taxes(info_lc),
      payments: get_payments(info_lc)
    }
  end

  def parse_specific_data("comprobanteRetencion", info_ret, content) do
    docs_sustento = content["docsSustento"]
    docs_list = if is_map(docs_sustento), do: List.wrap(docs_sustento["docSustento"]), else: []

    payments = Enum.flat_map(docs_list, &get_payments/1)

    total_retained =
      docs_list
      |> Enum.flat_map(fn doc ->
        rets = doc["retenciones"]
        if is_map(rets), do: List.wrap(rets["retencion"]), else: []
      end)
      |> Enum.map(fn ret ->
        Decimal.new(to_string(ret["valorRetenido"] || "0"))
      end)
      |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

    %{
      client_name: info_ret["razonSocialSujetoRetenido"],
      client_identification: info_ret["identificacionSujetoRetenido"],
      client_address: "",
      sub_total_without_taxes: Decimal.new("0.00"),
      total_discount: Decimal.new("0.00"),
      total: total_retained,
      taxes: [],
      payments: payments
    }
  end

  def parse_specific_data(_, _, _), do: %{}

  def get_items(content, root_tag) do
    details = get_details_by_doc_type(content, root_tag)

    items =
      details
      |> Enum.filter(&is_map/1)
      |> Enum.map(&format_item(&1, root_tag))

    [@headers | items]
  end

  defp get_details_by_doc_type(content, "guiaRemision") do
    destinatarios = content["destinatarios"]
    dests = if is_map(destinatarios), do: List.wrap(destinatarios["destinatario"]), else: []

    Enum.flat_map(dests, &extract_guia_details/1)
  end

  defp get_details_by_doc_type(content, "notaDebito") do
    node = content["motivos"]
    if is_map(node), do: List.wrap(node["motivo"]), else: []
  end

  defp get_details_by_doc_type(content, "comprobanteRetencion") do
    docs_sustento = content["docsSustento"]
    docs_list = if is_map(docs_sustento), do: List.wrap(docs_sustento["docSustento"]), else: []

    Enum.flat_map(docs_list, &extract_retencion_details/1)
  end

  defp get_details_by_doc_type(content, _) do
    node = content["detalles"]
    if is_map(node), do: List.wrap(node["detalle"]), else: []
  end

  defp extract_guia_details(dest) do
    detalles = dest["detalles"]
    if is_map(detalles), do: List.wrap(detalles["detalle"]), else: []
  end

  defp extract_retencion_details(doc) do
    rets = doc["retenciones"]
    ret_list = if is_map(rets), do: List.wrap(rets["retencion"]), else: []

    Enum.map(ret_list, fn r ->
      Map.merge(r, %{
        "numDocSustento" => doc["numDocSustento"],
        "codDocSustento" => doc["codDocSustento"],
        "fechaEmisionDocSustento" => doc["fechaEmisionDocSustento"]
      })
    end)
  end

  def format_item(item, "notaDebito") do
    [
      "",
      "",
      item["razon"],
      "",
      Decimal.new(item["valor"]),
      "1",
      Decimal.new("0.00"),
      Decimal.new(item["valor"])
    ]
  end

  def format_item(item, "guiaRemision") do
    [
      item["codigoInterno"],
      item["codigoAdicional"],
      item["descripcion"],
      get_item_extra_text(item),
      "",
      item["cantidad"],
      "",
      ""
    ]
  end

  def format_item(item, "comprobanteRetencion") do
    [
      item["numDocSustento"],
      item["codDocSustento"],
      item["fechaEmisionDocSustento"],
      "",
      Decimal.new(item["baseImponible"]),
      "RET #{item["codigo"]}",
      "#{item["porcentajeRetener"]}%",
      Decimal.new(item["valorRetenido"])
    ]
  end

  def format_item(item, _root_tag) do
    [
      item["codigoPrincipal"],
      item["codigoAuxiliar"],
      item["descripcion"],
      get_item_extra_text(item),
      Decimal.new(item["precioUnitario"]),
      Decimal.new(item["cantidad"]),
      Decimal.new(item["descuento"]),
      Decimal.new(item["precioTotalSinImpuesto"])
    ]
  end

  def get_item_extra_text(item) do
    detalles_adicionales = item["detallesAdicionales"]

    det_adicional_node =
      if is_map(detalles_adicionales), do: detalles_adicionales["detAdicional"]

    det_adicionales =
      cond do
        is_list(det_adicional_node) -> det_adicional_node
        is_map(det_adicional_node) -> [det_adicional_node]
        true -> []
      end

    det_adicionales
    |> Enum.filter(&is_map/1)
    |> Enum.reject(fn det -> det["-nombre"] == "informacionAdicional" end)
    |> Enum.map(fn det -> det["-valor"] end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  def get_additional_info(content) do
    info_adicional = content["infoAdicional"]
    campos = if is_map(info_adicional), do: info_adicional["campoAdicional"]

    campos_list =
      cond do
        is_list(campos) -> campos
        is_map(campos) -> [campos]
        true -> []
      end

    Enum.map(campos_list, fn %{"-nombre" => n, "#content" => v} -> %{name: n, value: to_string(v)} end)
  end

  def get_taxes(info_block) do
    total_con_impuestos = info_block["totalConImpuestos"]
    raw = if is_map(total_con_impuestos), do: total_con_impuestos["totalImpuesto"]

    taxes =
      cond do
        is_list(raw) -> raw
        is_map(raw) -> [raw]
        true -> []
      end

    Enum.map(taxes, fn %{"codigoPorcentaje" => code, "baseImponible" => total, "valor" => value} ->
      %{
        tax_value: Decimal.new(total || "0"),
        tax_total: Decimal.new(value || "0"),
        tax_code: code,
        tax_label: get_tax_label(code)
      }
    end)
  end

  def get_nd_taxes(info_block) do
    impuestos = info_block["impuestos"]
    raw = if is_map(impuestos), do: impuestos["impuesto"]

    taxes =
      cond do
        is_list(raw) -> raw
        is_map(raw) -> [raw]
        true -> []
      end

    Enum.map(taxes, fn %{"codigoPorcentaje" => code, "baseImponible" => total, "valor" => value} ->
      %{
        tax_value: Decimal.new(total || "0"),
        tax_total: Decimal.new(value || "0"),
        tax_code: code,
        tax_label: get_tax_label(code)
      }
    end)
  end

  def get_payments(info_block) do
    pagos = if is_map(info_block), do: info_block["pagos"]
    pago_nodes = if is_map(pagos), do: List.wrap(pagos["pago"]), else: []

    Enum.map(pago_nodes, fn p ->
      method = p["formaPago"] || p["formapago"]
      term = p["plazo"] || "0"
      total = p["total"] || "0.00"
      time = p["unidadTiempo"] || "Dias"

      %{
        method: decode_payment_method(method),
        total: Decimal.new(total || "0"),
        due_date: "#{term} #{time}"
      }
    end)
  end

  def decode_environment("1"), do: "PRUEBAS"
  def decode_environment("2"), do: "PRODUCCION"
  def decode_environment(v), do: v

  def decode_emission_type("1"), do: "NORMAL"
  def decode_emission_type(v), do: v

  def format_doc_number(info) do
    "#{info["estab"]}-#{info["ptoEmi"]}-#{info["secuencial"]}"
  end

  def truncate_address(nil), do: ""
  def truncate_address(address), do: String.slice(address, 0..110)

  def get_tax_label("0"), do: "IVA 0%"
  def get_tax_label("2"), do: "IVA 12%"
  def get_tax_label("3"), do: "IVA 14%"
  def get_tax_label("4"), do: "IVA 15%"
  def get_tax_label("10"), do: "IVA 13%"
  def get_tax_label("6"), do: "No objeto de impuesto"
  def get_tax_label("7"), do: "Exento de IVA"
  def get_tax_label(code), do: code

  def decode_payment_method("01"), do: "SIN UTILIZACION DEL SISTEMA FINANCIERO"
  def decode_payment_method("15"), do: "COMPENSACIÓN DE DEUDAS"
  def decode_payment_method("16"), do: "TARJETA DE DÉBITO"
  def decode_payment_method("17"), do: "DINERO ELECTRÓNICO"
  def decode_payment_method("18"), do: "TARJETA PREPAGO"
  def decode_payment_method("19"), do: "TARJETA DE CRÉDITO"
  def decode_payment_method("20"), do: "OTROS CON UTILIZACION DEL SISTEMA FINANCIERO"
  def decode_payment_method("21"), do: "ENDOSO DE TÍTULOS"
  def decode_payment_method(v), do: v
end
