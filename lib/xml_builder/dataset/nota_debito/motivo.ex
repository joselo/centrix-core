defmodule BillingCore.Dataset.NotaDebito.Motivo do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

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

  def to_doc(%BillingCore.Dataset.NotaDebito.Motivo{} = motivo) do
    valor = Decimal.round(motivo.valor, 2) |> Decimal.to_string(:normal)

    {
      :motivo,
      nil,
      [
        {:razon, nil, motivo.razon},
        {:valor, nil, valor}
      ]
    }
  end

  def to_xml(%BillingCore.Dataset.NotaDebito.Motivo{} = motivo) do
    to_doc(motivo)
    |> XmlBuilder.generate()
  end
end
