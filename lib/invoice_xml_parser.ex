defmodule CentrixCore.InvoiceXmlParser do
  @moduledoc """
  XML Invoice Parser (Legacy wrapper for DocumentXmlParser)
  """

  alias CentrixCore.DocumentXmlParser

  def parse_xml(xml), do: DocumentXmlParser.parse_xml(xml)
  def parse(xml_invoice), do: DocumentXmlParser.parse(xml_invoice)
  def get_authorization(xml_map), do: DocumentXmlParser.get_authorization(xml_map)

  def get_items(xml_invoice) do
    root = DocumentXmlParser.find_root_tag(xml_invoice)
    DocumentXmlParser.get_items(xml_invoice[root]["#content"], root)
  end

  def get_business_name(xml_invoice), do: parse(xml_invoice).business_name
  def get_tradename(xml_invoice), do: parse(xml_invoice).tradename
  def get_business_main_address(xml_invoice), do: parse(xml_invoice).business_main_address
  def get_business_branch_address(xml_invoice), do: parse(xml_invoice).business_branch_address
  def get_accounting(xml_invoice), do: parse(xml_invoice).accounting
  def get_accounting_number(xml_invoice), do: parse(xml_invoice).accounting_number
  def get_business_identification(xml_invoice), do: parse(xml_invoice).business_identification
  def get_access_key(xml_invoice), do: parse(xml_invoice).access_key
  def get_environment(xml_invoice), do: parse(xml_invoice).environment
  def get_emission_type(xml_invoice), do: parse(xml_invoice).emssion_type
  def get_client_name(xml_invoice), do: parse(xml_invoice).client_name
  def get_client_identification(xml_invoice), do: parse(xml_invoice).client_identification
  def get_client_address(xml_invoice), do: parse(xml_invoice).client_address
  def get_invoice_number(xml_invoice), do: parse(xml_invoice).invoice_number
  def get_currency(xml_invoice), do: parse(xml_invoice).currency
  def get_taxes(xml_invoice), do: parse(xml_invoice).taxes

  def get_client_fields(xml_invoice) do
    %{other_info: parse(xml_invoice).other_info}
  end

  def get_totals(xml_invoice) do
    doc = parse(xml_invoice)

    %{
      sub_total_without_taxes: doc.sub_total_without_taxes,
      total_discount: doc.total_discount,
      total: doc.total
    }
  end

  def get_payments(xml_invoice) do
    %{payments: parse(xml_invoice).payments}
  end
end
