defmodule CentrixCore.InvoicePdfBuilder do
  @moduledoc """
  PDF Invoice Renderer (Legacy wrapper for RidePdfBuilder)
  """

  alias CentrixCore.RidePdfBuilder

  def build(xml_map, logo_path \\ nil, bar_code_path \\ nil) do
    RidePdfBuilder.build(xml_map, logo_path, bar_code_path)
  end
end
