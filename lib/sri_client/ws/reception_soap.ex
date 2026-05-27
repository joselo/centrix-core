defmodule BillingCore.Ws.ReceptionSoap do
  @moduledoc false

  def create_request(xml, operation) when is_atom(operation) do
    get_xml(xml, operation)
  end

  defp soap_env(xml, operation) do
    {
      :"soapenv:Envelope",
      %{
        "xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
        "xmlns:ec": "http://ec.gob.sri.ws.recepcion"
      },
      [
        {:"soapenv:Header", nil, nil},
        {
          :"soapenv:Body",
          nil,
          [
            {
              :"ec:#{operation}",
              nil,
              [
                {:xml, nil, xml}
              ]
            }
          ]
        }
      ]
    }
  end

  defp get_xml(xml, operation) do
    xml
    |> Base.encode64()
    |> soap_env(Atom.to_string(operation))
    |> XmlBuilder.generate()
  end
end
