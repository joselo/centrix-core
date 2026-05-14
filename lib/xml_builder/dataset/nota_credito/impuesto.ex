defmodule BillingCore.Dataset.NotaCredito.Impuesto do
  @moduledoc false

  @decimals BillingCore.decimals()

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:codigo, :integer)
    field(:codigo_porcentaje, :integer)
    field(:tarifa, :decimal)
    field(:base_imponible, :decimal)
    field(:valor, :decimal)
  end

  def changeset(impuesto, params) do
    impuesto
    |> cast(params, [:codigo, :codigo_porcentaje, :tarifa, :base_imponible, :valor])
    |> validate_required([:codigo, :codigo_porcentaje, :tarifa, :base_imponible, :valor])
    |> validate_number(:codigo, greater_than_or_equal_to: 0, less_than: 10)
    |> validate_number(:codigo_porcentaje, greater_than_or_equal_to: 0, less_than: 10000)
  end

  def to_doc(%BillingCore.Dataset.NotaCredito.Impuesto{} = impuesto, decimals \\ @decimals) do
    {
      :impuesto,
      nil,
      [
        {:codigo, nil, impuesto.codigo},
        {:codigoPorcentaje, nil, impuesto.codigo_porcentaje},
        {:tarifa, nil, Decimal.round(impuesto.tarifa, decimals) |> Decimal.to_string(:normal)},
        {:baseImponible, nil,
         Decimal.round(impuesto.base_imponible, decimals) |> Decimal.to_string(:normal)},
        {:valor, nil, Decimal.round(impuesto.valor, decimals) |> Decimal.to_string(:normal)}
      ]
    }
  end

  def to_xml(%BillingCore.Dataset.NotaCredito.Impuesto{} = impuesto) do
    to_doc(impuesto)
    |> XmlBuilder.generate()
  end
end
