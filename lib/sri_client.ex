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

  @health_check_timeout 5_000

  def check_health(environment, opts \\ []) when is_integer(environment) and is_list(opts) do
    timeout = Keyword.get(opts, :timeout, @health_check_timeout)
    client_opts = [timeout: timeout, recv_timeout: timeout]

    reception_status =
      case check_reception(environment, client_opts) do
        {:ok, _} -> :up
        {:error, _} -> :down
      end

    authorization_status =
      case check_authorization(environment, client_opts) do
        {:ok, _} -> :up
        {:error, _} -> :down
      end

    {:ok, %{reception: reception_status, authorization: authorization_status}}
  end

  defp check_reception(environment, client_opts) do
    xml = "<comprobante><health>check</health></comprobante>"
    params = Ws.ReceptionSoap.create_request(xml, :validarComprobante)

    case Client.post(get_reception_url(environment), params, client_opts) do
      {:ok, response} ->
        ReceptionParser.parse_response(response)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp check_authorization(environment, client_opts) do
    dummy_key = String.duplicate("0", 49)
    params = Ws.AuthorizationSoap.create_request(dummy_key, :autorizacionComprobante)

    case Client.post(get_authorization_url(environment), params, client_opts) do
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
