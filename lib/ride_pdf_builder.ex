defmodule BillingCore.RidePdfBuilder do
  @moduledoc """
  Generic RIDE PDF Builder.
  Handles layout and dispatching for different SRI documents.
  """

  @table_opts [
    padding: 2,
    border: 0.1,
    repeat_header: 1,
    cols: [
      [width: 50, font_size: 7],
      [width: 50, font_size: 7],
      [width: 140, font_size: 7],
      [width: 60, font_size: 7],
      [width: 50, align: :right, font_size: 7],
      [width: 50, align: :right, font_size: 7],
      [width: 50, align: :right, font_size: 7],
      [width: 50, align: :right, font_size: 7]
    ],
    rows: %{
      0 => [
        bold: true,
        align: :center,
        kerning: true,
        background: :gainsboro
      ]
    }
  ]

  def build(xml_map, logo_path \\ nil, bar_code_path \\ nil) do
    document = xml_map.document
    symbol = currency_symbol(document.currency)

    # Prepare totals table
    totals_table = prepare_totals_table(document, symbol)

    # Format numeric columns in items table
    [header | item_rows] = document.items

    formatted_items = [
      header
      | Enum.map(item_rows, fn row ->
          row
          |> List.update_at(4, &format_amount(&1, symbol))
          |> List.update_at(5, &format_amount/1)
          |> List.update_at(6, &format_amount(&1, symbol))
          |> List.update_at(7, &format_amount(&1, symbol))
        end)
    ]

    document =
      document
      |> Map.put(:auth_datetime, xml_map.authorization_date)
      |> Map.put(:totals_table, totals_table)
      |> Map.put(:totals_row_count, length(totals_table))
      |> Map.put(:items, formatted_items)
      |> Map.put(:currency_symbol, symbol)

    {:ok, pdf} = Pdf.new(size: :a4, compress: false)

    pdf =
      pdf
      |> Pdf.set_info(
        title: "RIDE - #{document.invoice_number}",
        producer: "BillingCore",
        creator: "BillingCore",
        created: Date.utc_today(),
        modified: Date.utc_today(),
        author: document.business_name
      )
      |> Pdf.set_font("Helvetica", 10)

    pdf = render(pdf, document, logo_path, bar_code_path)

    Pdf.export(pdf)
  end

  defp render(pdf, document, logo_path, bar_code_path) do
    {pdf, grid} =
      pdf
      |> add_header(document, logo_path, bar_code_path)
      |> render_body_top(document)
      |> render_table(document)

    pdf = add_footer(pdf, document)
    add_table({pdf, grid}, document, logo_path, bar_code_path)
  end

  defp add_header(pdf, doc, logo_path, bar_code_path) do
    %{width: width, height: _height} = Pdf.size(pdf)

    contribuyente_especial = if is_nil(doc.accounting_number), do: "NO", else: "SI"

    business_table = [
      ["Razón social:", doc.tradename],
      ["Dirección Matriz:", doc.business_main_address],
      ["Dirección Sucursal:", doc.business_branch_address],
      ["Obligado a llevar contabilidad:", doc.accounting],
      ["Contribuyente Especial:", contribuyente_especial]
    ]

    {pdf, _} =
      pdf
      |> Pdf.set_font("Helvetica", 10)
      |> Pdf.set_font_size(7)
      |> add_logo(logo_path, doc.root_tag)
      # ── Document meta (top-right) ────────────────────────────────────
      |> Pdf.text_at({310, 790}, document_label(doc.root_tag) <> " Nro.", bold: true)
      |> Pdf.text_at({310, 780}, doc.invoice_number)
      |> Pdf.text_at({430, 790}, "R.U.C.", bold: true)
      |> Pdf.text_at({430, 780}, doc.business_identification)
      |> Pdf.text_at({310, 760}, "Fecha de Autorización", bold: true)
      |> Pdf.text_at({310, 750}, "#{doc.auth_datetime}")
      |> Pdf.text_at({430, 760}, "Ambiente", bold: true)
      |> Pdf.text_at({430, 750}, doc.environment)
      |> Pdf.text_at({490, 760}, "Emisión", bold: true)
      |> Pdf.text_at({490, 750}, doc.emssion_type)
      |> Pdf.text_at({310, 735}, "Número de Autorización", bold: true)
      |> add_bar_code(bar_code_path)
      |> Pdf.text_at({310, 700}, doc.access_key)
      # ── Horizontal divider below header ─────────────────────────────
      |> Pdf.set_line_width(0.3)
      |> Pdf.line({50, 695}, {width - 50, 695})
      |> Pdf.stroke()
      # ── Business name ────────────────────────────────────────────────
      |> Pdf.set_font_size(9)
      |> Pdf.text_at({310, 680}, doc.business_name, bold: true)
      |> Pdf.set_font_size(7)
      # ── Business mini-table (right) ──────────────────────────────────
      |> Pdf.table({310, 672}, {240, 72}, business_table,
        padding: 2,
        border: 0,
        cols: [[width: 115, bold: true, font_size: 7], [width: 125, font_size: 7]]
      )

    pdf
  end

  defp render_body_top(pdf, doc) do
    # This renders the client info and document-specific info (like modified doc for NC)
    client_table = [
      ["Razón Social/Nombres y Apellidos:", doc.client_name],
      ["RUC/CI:", doc.client_identification],
      ["Dirección:", doc.client_address]
    ]

    specific_table =
      case doc.root_tag do
        "notaCredito" ->
          [
            [
              "Comprobante que se modifica:",
              "#{doc.modified_doc_type} #{doc.modified_doc_number}"
            ],
            ["Fecha Emisión (Comprobante a modificar):", doc.modified_doc_date],
            ["Motivo de Modificación:", doc.reason]
          ]

        _ ->
          []
      end

    {pdf, _} =
      pdf
      |> Pdf.set_font_size(8)
      |> Pdf.text_at({50, 680}, "Receptor", bold: true)
      |> Pdf.set_font_size(7)
      |> Pdf.table({50, 672}, {260, 60}, client_table,
        padding: 2,
        border: 0,
        cols: [[width: 115, bold: true, font_size: 7], [width: 145, font_size: 7]]
      )

    {pdf, _} =
      if specific_table != [] do
        Pdf.table(pdf, {50, 620}, {260, 45}, specific_table,
          padding: 1,
          border: 0,
          cols: [[width: 115, bold: true, font_size: 6], [width: 145, font_size: 6]]
        )
      else
        {pdf, nil}
      end

    # Horizontal divider
    pdf
    |> Pdf.set_line_width(0.3)
    |> Pdf.line({50, 600}, {Pdf.size(pdf).width - 50, 600})
    |> Pdf.stroke()
  end

  defp render_table(pdf, %{items: items}) do
    Pdf.table(pdf, {50, 560}, {500, 350}, items, @table_opts)
  end

  defp add_footer(pdf, doc) do
    %{width: width, height: _height} = Pdf.size(pdf)
    items_bottom = Pdf.cursor(pdf)
    text_cursor = items_bottom - 20
    page_number = "#{Pdf.page_number(pdf)}"
    symbol = Map.get(doc, :currency_symbol, "")

    pdf = Pdf.set_font_size(pdf, 7)

    # Info Adicional
    {pdf, next_cursor} =
      case Map.get(doc, :other_info, []) do
        [] ->
          {pdf, text_cursor}

        other_info ->
          pdf =
            pdf
            |> Pdf.set_font_size(8)
            |> Pdf.text_at({55, text_cursor}, "Información Adicional", bold: true)
            |> Pdf.set_line_width(0.1)
            |> Pdf.line({50, text_cursor + 12}, {390, text_cursor + 12})
            |> Pdf.line({50, text_cursor - 80}, {390, text_cursor - 80})
            |> Pdf.line({50, text_cursor + 12}, {50, text_cursor - 80})
            |> Pdf.line({390, text_cursor + 12}, {390, text_cursor - 80})
            |> Pdf.stroke()

          other_info_table =
            Enum.map(other_info, fn field -> [field.name <> ":", field.value] end)

          {pdf, _} =
            Pdf.table(pdf, {55, text_cursor - 10}, {330, 65}, other_info_table,
              padding: 2,
              border: 0,
              cols: [[width: 90, bold: true, font_size: 7], [width: 240, font_size: 7]]
            )

          {pdf, text_cursor - 95}
      end

    # Payments (Only for Factura)
    pdf =
      if doc.root_tag == "factura" and Map.has_key?(doc, :payments) do
        payment_table = [
          ["Forma de Pago", ""],
          ["Método", doc.payments.method],
          ["Moneda", doc.currency],
          ["Plazo", doc.payments.due_date],
          ["Total", format_amount(doc.payments.total, symbol)]
        ]

        {pdf, _} =
          Pdf.table(pdf, {50, next_cursor}, {220, 70}, payment_table,
            padding: 2,
            border: 0.1,
            cols: [[width: 80, bold: true, font_size: 7], [width: 140, font_size: 7]],
            rows: %{0 => [bold: true, background: :gainsboro, font_size: 8]}
          )

        pdf
      else
        pdf
      end

    # Totals
    row_count = Map.get(doc, :totals_row_count, 5)
    totals_height = max(row_count * 14, 60)

    {pdf, _} =
      Pdf.table(pdf, {400, items_bottom}, {150, totals_height}, doc.totals_table,
        padding: 2,
        border: 0.1,
        cols: [[width: 220, bold: true], [width: 220, align: :right]],
        rows: %{row_count => [bold: true, background: :gainsboro]}
      )

    Pdf.text_wrap!(pdf, {20, 100}, {width - 40, 20}, "Página #{page_number}", align: :center)
  end

  defp add_table({pdf, :complete}, _doc, _l, _b), do: pdf

  defp add_table({pdf, {:continue, _} = remaining}, doc, logo_path, bar_code_path) do
    pdf =
      pdf
      |> Pdf.add_page(:a4)
      |> add_header(doc, logo_path, bar_code_path)
      |> render_body_top(doc)

    {pdf, grid} = Pdf.table(pdf, {50, 560}, {500, 300}, remaining, @table_opts)

    pdf = add_footer(pdf, doc)
    add_table({pdf, grid}, doc, logo_path, bar_code_path)
  end

  # Helpers
  defp prepare_totals_table(doc, symbol) do
    subtotals =
      Enum.map(doc.taxes, fn tax ->
        [String.replace(tax.tax_label, "IVA", "SUBTOTAL"), format_amount(tax.tax_value, symbol)]
      end)

    iva_rates =
      Enum.map(doc.taxes, fn tax ->
        [tax.tax_label, format_amount(tax.tax_total, symbol)]
      end)

    subtotals ++
      [
        ["SUBTOTAL S/IMP.", format_amount(doc.sub_total_without_taxes, symbol)],
        ["DESCUENTO", format_amount(doc.total_discount, symbol)]
      ] ++ iva_rates ++ [["Total", format_amount(doc.total, symbol)]]
  end

  defp document_label("factura"), do: "FACTURA"
  defp document_label("notaCredito"), do: "NOTA DE CRÉDITO"
  defp document_label("notaDebito"), do: "NOTA DE DÉBITO"
  defp document_label("comprobanteRetencion"), do: "COMPROBANTE DE RETENCIÓN"
  defp document_label("guiaRemision"), do: "GUÍA DE REMISIÓN"
  defp document_label("liquidacionCompra"), do: "LIQUIDACIÓN DE COMPRA"
  defp document_label(_), do: "COMPROBANTE"

  defp add_logo(pdf, nil, tag) do
    pdf
    |> Pdf.set_font("Helvetica", 20)
    |> Pdf.text_at({50, 775}, document_label(tag), bold: true)
    |> Pdf.set_font("Helvetica", 10)
    |> Pdf.set_font_size(7)
  end

  defp add_logo(pdf, path, _), do: Pdf.add_image(pdf, {50, 700}, path, height: 100)

  defp add_bar_code(pdf, nil), do: pdf
  defp add_bar_code(pdf, path), do: Pdf.add_image(pdf, {305, 705}, path, width: 235, height: 28)

  defp currency_symbol("DOLAR"), do: "$"
  defp currency_symbol("USD"), do: "$"
  defp currency_symbol(nil), do: "$"
  defp currency_symbol(c), do: c

  defp format_amount(nil), do: "0.00"

  defp format_amount(v) when is_binary(v) do
    case String.split(v, ".") do
      [i, d] -> "#{format_integer(i)}.#{d}"
      [i] -> format_integer(i)
    end
  end

  defp format_amount(v), do: to_string(v)
  defp format_amount(v, s), do: "#{s} #{format_amount(v)}"

  defp format_integer(str) do
    {sign, digits} =
      if String.starts_with?(str, "-"), do: {"-", String.slice(str, 1..-1//1)}, else: {"", str}

    formatted =
      digits
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.join(",")
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.join()

    "#{sign}#{formatted}"
  end
end
