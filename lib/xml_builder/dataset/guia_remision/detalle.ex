defmodule BillingCore.Dataset.GuiaRemision.Detalle do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.Factura.DetAdicional
  alias BillingCore.Dataset.GuiaRemision.Detalle

  embedded_schema do
    field(:codigo_interno, :string)
    field(:codigo_adicional, :string)
    field(:descripcion, :string)
    field(:cantidad, :decimal)

    embeds_many(:detalles_adicionales, DetAdicional)
  end

  def changeset(detalle, params \\ %{}) do
    detalle
    |> cast(params, [
      :codigo_interno,
      :codigo_adicional,
      :descripcion,
      :cantidad
    ])
    |> validate_required([
      :descripcion,
      :cantidad
    ])
    |> validate_length(:descripcion, max: 300)
    |> cast_embed(:detalles_adicionales, with: &DetAdicional.changeset/2)
  end

  def to_doc(%Detalle{} = detalle) do
    doc =
      [
        {:descripcion, nil, detalle.descripcion},
        {:cantidad, nil, detalle.cantidad |> Decimal.round(6) |> Decimal.to_string(:normal)}
      ]
      |> add_codigo_interno(detalle)
      |> add_codigo_adicional(detalle)
      |> add_detalles_adicionales(detalle)

    {
      :detalle,
      nil,
      doc
    }
  end

  def to_xml(%Detalle{} = detalle) do
    detalle
    |> to_doc()
    |> XmlBuilder.generate()
  end

  defp add_codigo_interno(doc, %{codigo_interno: nil}), do: doc

  defp add_codigo_interno(doc, %{codigo_interno: codigo_interno}) do
    List.insert_at(doc, 0, {:codigoInterno, nil, codigo_interno})
  end

  defp add_codigo_adicional(doc, %{codigo_adicional: nil}), do: doc

  defp add_codigo_adicional(doc, %{codigo_adicional: codigo_adicional}) do
    index = Enum.find_index(doc, fn {tag, _, _} -> tag == :descripcion end)
    List.insert_at(doc, index, {:codigoAdicional, nil, codigo_adicional})
  end

  defp add_detalles_adicionales(doc, %{detalles_adicionales: []}), do: doc

  defp add_detalles_adicionales(doc, %{detalles_adicionales: detalles}) do
    detalles_doc = Enum.map(detalles, &DetAdicional.to_doc/1)
    doc ++ [{:detallesAdicionales, nil, detalles_doc}]
  end
end
