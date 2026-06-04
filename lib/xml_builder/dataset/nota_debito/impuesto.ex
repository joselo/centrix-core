defmodule BillingCore.Dataset.NotaDebito.Impuesto do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.NotaDebito.Impuesto

  @decimals BillingCore.decimals()

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
    |> validate_number(:codigo_porcentaje, greater_than_or_equal_to: 0, less_than: 10_000)
  end

  def to_doc(%Impuesto{} = impuesto, decimals \\ @decimals) do
    {
      :impuesto,
      nil,
      [
        {:codigo, nil, impuesto.codigo},
        {:codigoPorcentaje, nil, impuesto.codigo_porcentaje},
        {:tarifa, nil, impuesto.tarifa |> Decimal.round(decimals) |> Decimal.to_string(:normal)},
        {:baseImponible, nil, impuesto.base_imponible |> Decimal.round(decimals) |> Decimal.to_string(:normal)},
        {:valor, nil, impuesto.valor |> Decimal.round(decimals) |> Decimal.to_string(:normal)}
      ]
    }
  end

  def to_xml(%Impuesto{} = impuesto) do
    impuesto
    |> to_doc()
    |> XmlBuilder.generate()
  end
end
