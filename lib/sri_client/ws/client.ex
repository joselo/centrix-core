defmodule CentrixCore.Ws.Client do
  @moduledoc false
  @behaviour CentrixCore.Ws.ClientBehaviour

  require Logger

  def post(wsdl_url, body, opts \\ []) do
    headers = [
      {"Content-Type", "text/xml;charset=UTF-8"}
    ]

    timeout = Keyword.get(opts, :timeout, CentrixCore.timeout())
    recv_timeout = Keyword.get(opts, :recv_timeout, CentrixCore.soap_server_recv_timeout())

    Req.post(wsdl_url,
      body: body,
      headers: headers,
      connect_options: [timeout: timeout],
      receive_timeout: recv_timeout,
      retry: false
    )
    |> handle_response()
  end

  def put(url, params) do
    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    body = URI.encode_query(params)

    Req.put(url,
      body: body,
      headers: headers,
      connect_options: [timeout: CentrixCore.timeout()],
      receive_timeout: CentrixCore.soap_server_recv_timeout(),
      retry: false
    )
    |> handle_response()
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: body}}) do
    {:ok, body}
  end

  # Catch-all for other status codes
  defp handle_response({:ok, %Req.Response{body: body}}) do
    {:error, body}
  end

  # Handle connection timeout
  defp handle_response({:error, %Req.TransportError{reason: :timeout}}) do
    {:error, "Tiempo de espera agotado al consultar al SRI"}
  end

  # Handle connection refused or DNS issues
  defp handle_response({:error, %Req.TransportError{reason: :econnrefused}}) do
    {:error, "No se pudo establecer conexión con los servidores del SRI"}
  end

  # Handle connection closed prematurely (typically overload or crash)
  defp handle_response({:error, %Req.TransportError{reason: :closed}}) do
    {:error, "La conexión fue cerrada inesperadamente por el SRI (posible sobrecarga o caída del servidor)"}
  end

  # Handle other errors like `:nxdomain`, etc.
  defp handle_response({:error, exception}) do
    {:error, "Error en la solicitud: #{inspect(exception)}"}
  end
end
