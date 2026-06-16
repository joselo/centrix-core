defmodule CentrixCore.Ws.Client do
  @moduledoc false
  @behaviour CentrixCore.Ws.ClientBehaviour

  require Logger

  def post(wsdl_url, body, opts \\ []) do
    headers = [
      {"Content-Encoding", "gzip"},
      {"Content-Type", "text/xml;charset=UTF-8"},
      {"Accept-Encoding", "gzip,deflate"},
      {"Vary", "Accept-Encoding"}
    ]

    timeout = Keyword.get(opts, :timeout, CentrixCore.timeout())
    recv_timeout = Keyword.get(opts, :recv_timeout, CentrixCore.soap_server_recv_timeout())

    wsdl_url
    |> HTTPoison.post(body, headers,
      timeout: timeout,
      recv_timeout: recv_timeout
    )
    |> handle_response()
  end

  def put(url, params) do
    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    body = URI.encode_query(params)

    url
    |> HTTPoison.put(body, headers,
      timeout: CentrixCore.timeout(),
      recv_timeout: CentrixCore.soap_server_recv_timeout()
    )
    |> handle_response()
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}}) do
    {:ok, unzip_body(body, headers)}
  end

  # Catch-all for other status codes
  defp handle_response({:ok, %HTTPoison.Response{status_code: _, body: body, headers: headers}}) do
    {:error, unzip_body(body, headers)}
  end

  # Handle connection timeout
  defp handle_response({:error, %HTTPoison.Error{reason: :timeout}}) do
    {:error, "Tiempo de espera agotado al consultar al SRI"}
  end

  # Handle connection refused or DNS issues
  defp handle_response({:error, %HTTPoison.Error{reason: :connect_timeout}}) do
    {:error, "No se pudo establecer conexión con los servidores del SRI"}
  end

  # Handle connection closed prematurely (typically overload or crash)
  defp handle_response({:error, %HTTPoison.Error{reason: :closed}}) do
    {:error, "La conexión fue cerrada inesperadamente por el SRI (posible sobrecarga o caída del servidor)"}
  end

  # Handle other errors like `:nxdomain`, etc.
  defp handle_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, "Error en la solicitud: #{inspect(reason)}"}
  end

  defp unzip_body(body, headers) do
    header_map = Map.new(headers)

    case header_map do
      %{"Content-Encoding" => "gzip"} ->
        :zlib.gunzip(body)

      _ ->
        body
    end
  end
end
