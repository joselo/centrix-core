defmodule CentrixCore.ReceptionParser do
  @moduledoc false
  import SweetXml

  def parse_response(response) do
    case xpath(parse(response, quiet: true), ~x"//RespuestaRecepcionComprobante/estado/text()"s) do
      nil ->
        {:error, response}

      status ->
        {:ok, %{status: status, response: response}}
    end
  catch
    :exit, _ -> {:error, response}
  end
end
