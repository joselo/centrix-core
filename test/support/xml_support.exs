defmodule BillingCore.Dataset.Test.XmlSupport do
  @moduledoc false
  def format(xml) do
    String.replace(xml, ~r/\r|\n/, "")
  end
end
