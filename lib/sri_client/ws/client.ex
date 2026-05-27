defmodule BillingCore.Ws.Client do
  @moduledoc false
  @behaviour BillingCore.Ws.ClientBehaviour

  require Logger

  def post(wsdl_url, body) do
    headers = [
      {"Content-Encoding", "gzip"},
      {"Content-Type", "text/xml;charset=UTF-8"},
      {"Accept-Encoding", "gzip,deflate"},
      {"Vary", "Accept-Encoding"}
    ]

    wsdl_url
    |> HTTPoison.post(body, headers,
      timeout: BillingCore.timeout(),
      recv_timeout: BillingCore.soap_server_recv_timeout()
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
      timeout: BillingCore.timeout(),
      recv_timeout: BillingCore.soap_server_recv_timeout()
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
    {:error, "Request timed out"}
  end

  # Handle connection refused or DNS issues
  defp handle_response({:error, %HTTPoison.Error{reason: :connect_timeout}}) do
    {:error, "Connection timed out"}
  end

  # Handle other errors like `:nxdomain`, `:closed`, etc.
  defp handle_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, "Request failed due to: #{inspect(reason)}"}
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
