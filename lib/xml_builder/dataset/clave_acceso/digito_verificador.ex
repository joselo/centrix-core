defmodule CentrixCore.Dataset.ClaveAcceso.DigitoVerificador do
  @moduledoc false

  def generate(
        %{
          fecha_emision: _,
          tipo_comprobante: _,
          ruc: _,
          ambiente: _,
          pto_emi: _,
          estab: _,
          secuencial: _,
          codigo: _,
          tipo_emision: _
        } = changes
      ) do
    string = changes_to_string(changes)
    mod = mod11(string)

    Enum.join([string, mod])
  end

  def changes_to_string(%{} = clave_acceso) do
    clave_acceso
    |> format()
    |> Enum.join()
  end

  def mod11(string) do
    {integer, _} =
      string
      |> String.reverse()
      |> Integer.parse()

    m =
      integer
      |> Integer.digits()
      |> sum_list()
      |> rem(11)

    case 11 - m do
      10 -> 1
      11 -> 0
      value -> value
    end
  end

  defp sum_list([h | t]) do
    x = 2
    h * x + sum_list(t, 2)
  end

  defp sum_list([h | t], c) when c < 7 do
    x = c + 1
    h * x + sum_list(t, x)
  end

  defp sum_list([h | t], _) do
    x = 2
    h * x + sum_list(t, x)
  end

  defp sum_list([], _) do
    0
  end

  defp format(%{} = clave_acceso) do
    day = clave_acceso.fecha_emision.day |> Integer.to_string() |> String.pad_leading(2, "0")
    month = clave_acceso.fecha_emision.month |> Integer.to_string() |> String.pad_leading(2, "0")

    fecha_emision = Enum.join([day, month, clave_acceso.fecha_emision.year])

    tipo_comprobante =
      clave_acceso.tipo_comprobante
      |> Integer.to_string()
      |> String.pad_leading(
        2,
        "0"
      )

    estab = clave_acceso.estab |> Integer.to_string() |> String.pad_leading(3, "0")
    pto_emi = clave_acceso.pto_emi |> Integer.to_string() |> String.pad_leading(3, "0")
    serie = "#{estab}#{pto_emi}"
    secuencial = clave_acceso.secuencial |> Integer.to_string() |> String.pad_leading(9, "0")
    codigo = clave_acceso.codigo |> Integer.to_string() |> String.pad_leading(8, "0")

    [
      fecha_emision,
      tipo_comprobante,
      clave_acceso.ruc,
      clave_acceso.ambiente,
      serie,
      secuencial,
      codigo,
      clave_acceso.tipo_emision
    ]
  end
end
