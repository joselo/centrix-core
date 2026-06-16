defmodule CentrixCore.Dataset.NotaDebito.Pago do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias CentrixCore.Dataset.NotaDebito.Pago

  @decimals CentrixCore.decimals()

  embedded_schema do
    field(:forma_pago, :integer)
    field(:total, :decimal)
    field(:plazo, :integer)
    field(:unidad_tiempo, :string)
  end

  def changeset(pago, params) do
    pago
    |> cast(params, [:forma_pago, :total, :plazo, :unidad_tiempo])
    |> validate_required([:forma_pago, :total])
  end

  def to_doc(%Pago{} = pago, decimals \\ @decimals) do
    doc =
      [
        {:formaPago, nil, pago.forma_pago |> Integer.to_string() |> String.pad_leading(2, "0")},
        {:total, nil, pago.total |> Decimal.round(decimals) |> Decimal.to_string(:normal)}
      ]
      |> add_plazo(pago)
      |> add_unidad_tiempo(pago)

    {
      :pago,
      nil,
      doc
    }
  end

  def to_xml(%Pago{} = pago) do
    pago
    |> to_doc()
    |> XmlBuilder.generate()
  end

  defp add_plazo(doc, %{plazo: nil}), do: doc

  defp add_plazo(doc, %{plazo: plazo}) do
    List.insert_at(doc, -1, {:plazo, nil, plazo})
  end

  defp add_unidad_tiempo(doc, %{unidad_tiempo: nil}), do: doc

  defp add_unidad_tiempo(doc, %{unidad_tiempo: unidad_tiempo}) do
    List.insert_at(doc, -1, {:unidadTiempo, nil, unidad_tiempo})
  end
end
