defmodule BillingCore.Dataset.NotaDebito.Impuesto do
  @moduledoc false

  @decimals BillingCore.decimals()

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:codigo, :integer)
    field(:codigo_porcentaje, :integer)
    field(:tarifa, :float)
    field(:base_imponible, :float)
    field(:valor, :float)
  end

  def changeset(impuesto, params) do
    impuesto
    |> cast(params, [:codigo, :codigo_porcentaje, :tarifa, :base_imponible, :valor])
    |> validate_required([:codigo, :codigo_porcentaje, :tarifa, :base_imponible, :valor])
  end

  def to_doc(%BillingCore.Dataset.NotaDebito.Impuesto{} = impuesto, decimals \\ @decimals) do
    {
      :impuesto,
      nil,
      [
        {:codigo, nil, impuesto.codigo},
        {:codigoPorcentaje, nil, impuesto.codigo_porcentaje},
        {:tarifa, nil, :erlang.float_to_binary(impuesto.tarifa, decimals: decimals)},
        {:baseImponible, nil,
         :erlang.float_to_binary(impuesto.base_imponible, decimals: decimals)},
        {:valor, nil, :erlang.float_to_binary(impuesto.valor, decimals: decimals)}
      ]
    }
  end

  def to_xml(%BillingCore.Dataset.NotaDebito.Impuesto{} = impuesto) do
    to_doc(impuesto)
    |> XmlBuilder.generate()
  end
end
