defmodule BillingCore.Dataset.NotaDebito.Motivo do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.NotaDebito.Motivo

  embedded_schema do
    field(:razon, :string)
    field(:valor, :decimal)
  end

  def changeset(motivo, params \\ %{}) do
    motivo
    |> cast(params, [
      :razon,
      :valor
    ])
    |> validate_required([
      :razon,
      :valor
    ])
    |> validate_length(:razon, max: 300)
  end

  def to_doc(%Motivo{} = motivo) do
    valor = motivo.valor |> Decimal.round(2) |> Decimal.to_string(:normal)

    {
      :motivo,
      nil,
      [
        {:razon, nil, motivo.razon},
        {:valor, nil, valor}
      ]
    }
  end

  def to_xml(%Motivo{} = motivo) do
    motivo
    |> to_doc()
    |> XmlBuilder.generate()
  end
end
