defmodule BillingCore.Dataset.NotaDebito.Pago do
  @moduledoc false

  @decimals BillingCore.decimals()

  use Ecto.Schema
  import Ecto.Changeset

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

  def to_doc(%BillingCore.Dataset.NotaDebito.Pago{} = pago, decimals \\ @decimals) do
    doc =
      [
        {:formaPago, nil, Integer.to_string(pago.forma_pago) |> String.pad_leading(2, "0")},
        {:total, nil, Decimal.round(pago.total, decimals) |> Decimal.to_string(:normal)}
      ]
      |> add_plazo(pago)
      |> add_unidad_tiempo(pago)

    {
      :pago,
      nil,
      doc
    }
  end

  def to_xml(%BillingCore.Dataset.NotaDebito.Pago{} = pago) do
    to_doc(pago)
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
