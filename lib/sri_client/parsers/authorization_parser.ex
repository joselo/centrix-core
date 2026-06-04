defmodule BillingCore.AuthorizationParser do
  @moduledoc false
  import SweetXml

  def parse_response(response) do
    case xpath(parse(response, quiet: true), ~x"//autorizacion/estado/text()"s) do
      nil ->
        {:error, response}

      status ->
        {:ok, %{status: verify_status(status), response: response}}
    end
  catch
    :exit, _ -> {:error, response}
  end

  defp verify_status(nil), do: "NO ENCONTRADO O PENDIENTE"
  defp verify_status(""), do: "NO ENCONTRADO O PENDIENTE"
  defp verify_status(status), do: status
end
