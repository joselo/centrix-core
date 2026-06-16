defmodule CentrixCore.Dataset.Factura.Pago do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias CentrixCore.Dataset.Factura.Pago

  @decimals CentrixCore.decimals()

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
    |> validate_number(:forma_pago, greater_than_or_equal_to: 1, less_than: 100)
    |> validate_length(:unidad_tiempo, max: 10)
  end

  def to_doc(key, %Pago{} = pago, decimals \\ @decimals) when is_atom(key) do
    {
      key,
      nil,
      [
        {:formaPago, nil, pago.forma_pago |> Integer.to_string() |> String.pad_leading(2, "0")},
        {:total, nil, pago.total |> Decimal.round(decimals) |> Decimal.to_string(:normal)},
        {:plazo, nil, pago.plazo},
        {:unidadTiempo, nil, pago.unidad_tiempo}
      ]
    }
  end

  def to_xml(key, %Pago{} = pago) when is_atom(key) do
    key
    |> to_doc(pago)
    |> XmlBuilder.generate()
  end
end
