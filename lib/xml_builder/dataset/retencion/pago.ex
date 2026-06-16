defmodule CentrixCore.Dataset.Retencion.Pago do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias CentrixCore.Dataset.Retencion.Pago

  @decimals CentrixCore.decimals()

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

  def to_doc(%Pago{} = pago) do
    doc = [
      {:formaPago, nil, pago.forma_pago},
      {:total, nil, pago.total |> Decimal.round(@decimals) |> Decimal.to_string(:normal)}
    ]

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
end
