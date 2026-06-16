defmodule CentrixCore.Xbes.SignedInfo.Doc do
  @moduledoc false

  def digest(xml) do
    canon = canonicalize(xml)

    :sha
    |> :crypto.hash(canon)
    |> Base.encode64()
  end

  def canonicalize(value) do
    value
    |> SweetXml.parse(namespace_conformant: true, document: true)
    |> XmerlC14n.canonicalize!()
  end
end
