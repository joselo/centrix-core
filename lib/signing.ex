defmodule CentrixCore.Signing do
  @moduledoc false

  alias CentrixCore.P12Reader
  alias CentrixCore.Xbes

  def sign(xml, p12_path, p12_password) do
    signing_time =
      CentrixCore.timezone()
      |> Timex.now()
      |> Timex.format!("%FT%T%:z", :strftime)

    case P12Reader.read(p12_path, p12_password) do
      {:ok, cert, rsa} ->
        Xbes.sign(xml, cert, rsa, signing_time)

      {:error, error} ->
        {:error, error}
    end
  end
end
