defmodule CentrixCore.Xbes.Util do
  @moduledoc false

  def digest(value) do
    value
    |> hash()
    |> Base.encode64()
  end

  def hash(value) do
    :crypto.hash(:sha, value)
  end

  def attrs(id_attr, xmlns_attr) do
    if xmlns_attr do
      attrs = [
        "xmlns:ds": "http://www.w3.org/2000/09/xmldsig#",
        "xmlns:etsi": "http://uri.etsi.org/01903/v1.3.2#",
        Id: id_attr
      ]

      {attrs, ""}
    else
      {[Id: id_attr], nil}
    end
  end
end
