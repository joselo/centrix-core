defmodule BillingCore.Dataset.NotaCredito.TotalImpuesto do
  @moduledoc false

  @decimals BillingCore.decimals()

  use Ecto.Schema
  import Ecto.Changeset

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
  end

  def to_doc(
        %BillingCore.Dataset.NotaCredito.TotalImpuesto{} = total_impuesto,
        decimals \\ @decimals
      ) do
    {
      :totalImpuesto,
      nil,
      [
        {:codigo, nil, total_impuesto.codigo},
        {:codigoPorcentaje, nil, total_impuesto.codigo_porcentaje},
        {:baseImponible, nil,
         Decimal.round(total_impuesto.base_imponible, decimals) |> Decimal.to_string(:normal)},
        {:valor, nil, Decimal.round(total_impuesto.valor, decimals) |> Decimal.to_string(:normal)}
      ]
    }
  end

  def to_xml(%BillingCore.Dataset.NotaCredito.TotalImpuesto{} = total_impuesto) do
    to_doc(total_impuesto)
    |> XmlBuilder.generate()
  end
end
