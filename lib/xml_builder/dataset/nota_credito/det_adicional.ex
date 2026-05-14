defmodule BillingCore.Dataset.NotaCredito.DetAdicional do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:nombre, :string)
    field(:valor, :string)
  end

  def changeset(det_adicional, params) do
    det_adicional
    |> cast(params, [:nombre, :valor])
    |> validate_required([:nombre, :valor])
  end

  def to_doc(%BillingCore.Dataset.NotaCredito.DetAdicional{} = detAdicional) do
    {
      :detAdicional,
      [valor: detAdicional.valor, nombre: detAdicional.nombre],
      nil
    }
  end

  def to_xml(%BillingCore.Dataset.NotaCredito.DetAdicional{} = detAdicional) do
    to_doc(detAdicional)
    |> XmlBuilder.generate()
  end
end
