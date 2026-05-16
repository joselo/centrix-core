defmodule BillingCore.Dataset.Retencion.Pago do
  @moduledoc false

  @decimals BillingCore.decimals()

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:forma_pago, :string)
    field(:total, :decimal)
  end

  def changeset(pago, params \\ %{}) do
    pago
    |> cast(params, [
      :forma_pago,
      :total
    ])
    |> validate_required([
      :forma_pago,
      :total
    ])
  end

  def to_doc(%BillingCore.Dataset.Retencion.Pago{} = pago) do
    doc = [
      {:formaPago, nil, pago.forma_pago},
      {:total, nil, Decimal.round(pago.total, @decimals) |> Decimal.to_string(:normal)}
    ]

    {
      :pago,
      nil,
      doc
    }
  end

  def to_xml(%BillingCore.Dataset.Retencion.Pago{} = pago) do
    to_doc(pago)
    |> XmlBuilder.generate()
  end
end
