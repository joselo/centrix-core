defmodule BillingCore.Ws.AuthorizationSoap do
  @moduledoc false

  def create_request(clave_acceso, operation) when is_atom(operation) do
    get_clave_acceso(clave_acceso, operation)
  end

  defp soap_env(clave_acceso, operation) do
    {
      :"soapenv:Envelope",
      [
        "xmlns:ec": "http://ec.gob.sri.ws.autorizacion",
        "xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/"
      ],
      [
        {:"soapenv:Header", nil, nil},
        {
          :"soapenv:Body",
          nil,
          [
            {
              "ec:#{operation}",
              nil,
              [
                {:claveAccesoComprobante, nil, clave_acceso}
              ]
            }
          ]
        }
      ]
    }
  end

  defp get_clave_acceso(clave_acceso, operation) do
    # |> Base.encode64()
    clave_acceso
    |> soap_env(Atom.to_string(operation))
    |> XmlBuilder.generate()
  end
end
