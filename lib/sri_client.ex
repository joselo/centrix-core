defmodule BillingCore.SriClient do
  @moduledoc false
  alias BillingCore.AuthorizationParser
  alias BillingCore.ReceptionParser
  alias BillingCore.Ws
  alias BillingCore.Ws.Client

  def send_document(xml, environment) do
    params = Ws.ReceptionSoap.create_request(xml, :validarComprobante)

    case Client.post(get_reception_url(environment), params) do
      {:ok, response} ->
        ReceptionParser.parse_response(response)

      {:error, response} ->
        {:error, response}
    end
  end

  def is_authorized(clave_acceso, environment) when is_binary(clave_acceso) and is_integer(environment) do
    params = Ws.AuthorizationSoap.create_request(clave_acceso, :autorizacionComprobante)

    case Client.post(get_authorization_url(environment), params) do
      {:ok, response} ->
        AuthorizationParser.parse_response(response)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_reception_url(1) do
    BillingCore.reception_url()
  end

  defp get_reception_url(2) do
    BillingCore.prod_reception_url()
  end

  def get_authorization_url(1) do
    BillingCore.authorization_url()
  end

  def get_authorization_url(2) do
    BillingCore.prod_authorization_url()
  end
end
