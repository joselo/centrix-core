defmodule BillingCore.Dataset.Factura.DetAdicional do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.Factura.DetAdicional

  embedded_schema do
    field(:nombre, :string)
    field(:valor, :string)
  end

  def changeset(det_adicional, params) do
    det_adicional
    |> cast(params, [:nombre, :valor])
    |> validate_required([:nombre, :valor])
  end

  def to_doc(%DetAdicional{} = detAdicional) do
    {
      :detAdicional,
      [valor: detAdicional.valor, nombre: detAdicional.nombre],
      nil
    }
  end

  def to_xml(%DetAdicional{} = detAdicional) do
    detAdicional
    |> to_doc()
    |> XmlBuilder.generate()
  end
end
