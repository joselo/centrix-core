defmodule BillingCore.Dataset.Factura.TotalImpuesto do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.Factura.TotalImpuesto

  @decimals BillingCore.decimals()

  embedded_schema do
    field(:codigo, :integer)
    field(:codigo_porcentaje, :integer)
    field(:base_imponible, :decimal)
    field(:valor, :decimal)
  end

  def changeset(total_impuesto, params) do
    total_impuesto
    |> cast(params, [:codigo, :codigo_porcentaje, :base_imponible, :valor])
    |> validate_required([:codigo, :codigo_porcentaje, :base_imponible, :valor])
    |> validate_number(:codigo, greater_than_or_equal_to: 0, less_than: 10)
    |> validate_number(:codigo_porcentaje, greater_than_or_equal_to: 0, less_than: 10_000)
  end

  def to_doc(%TotalImpuesto{} = total_impuesto, decimals \\ @decimals) do
    {
      :totalImpuesto,
      nil,
      [
        {:codigo, nil, total_impuesto.codigo},
        {:codigoPorcentaje, nil, total_impuesto.codigo_porcentaje},
        {:baseImponible, nil, total_impuesto.base_imponible |> Decimal.round(decimals) |> Decimal.to_string(:normal)},
        {:valor, nil, total_impuesto.valor |> Decimal.round(decimals) |> Decimal.to_string(:normal)}
      ]
    }
  end

  def to_xml(%TotalImpuesto{} = total_impuesto) do
    total_impuesto
    |> to_doc()
    |> XmlBuilder.generate()
  end
end
