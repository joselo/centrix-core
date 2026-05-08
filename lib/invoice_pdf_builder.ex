defmodule BillingCore.InvoicePdfBuilder do
  @moduledoc """
  PDF Invoice Renderer (Legacy wrapper for RidePdfBuilder)
  """

  alias BillingCore.RidePdfBuilder

  def build(xml_map, logo_path \\ nil, bar_code_path \\ nil) do
    RidePdfBuilder.build(xml_map, logo_path, bar_code_path)
  end
end
