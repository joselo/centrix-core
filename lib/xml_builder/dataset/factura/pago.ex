defmodule BillingCore.Dataset.Factura.Pago do
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

  def changeset(impuesto, params) do
    impuesto
    |> cast(params, [:forma_pago, :total, :plazo, :unidad_tiempo])
    |> validate_required([:forma_pago, :total, :plazo, :unidad_tiempo])
  end

  def to_doc(key, %BillingCore.Dataset.Factura.Pago{} = pago, decimals \\ @decimals)
      when is_atom(key) do
    {
      key,
      nil,
      [
        {:formaPago, nil, Integer.to_string(pago.forma_pago) |> String.pad_leading(2, "0")},
        {:total, nil, Decimal.round(pago.total, decimals) |> Decimal.to_string(:normal)},
        {:plazo, nil, pago.plazo},
        {:unidadTiempo, nil, pago.unidad_tiempo}
      ]
    }
  end

  def to_xml(key, %BillingCore.Dataset.Factura.Pago{} = pago) when is_atom(key) do
    to_doc(key, pago)
    |> XmlBuilder.generate()
  end
end
