defmodule CentrixCore.Dataset.Factura.Detalle do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias CentrixCore.Dataset.Factura.DetAdicional
  alias CentrixCore.Dataset.Factura.Detalle
  alias CentrixCore.Dataset.Factura.Impuesto

  @decimals CentrixCore.decimals()

  embedded_schema do
    field(:codigo_principal, :string)
    field(:codigo_auxiliar, :string)
    field(:descripcion, :string)
    field(:cantidad, :decimal)
    field(:precio_unitario, :decimal)
    field(:descuento, :decimal)
    field(:precio_total_sin_impuesto, :decimal)

    embeds_many(:detalles_adicionales, DetAdicional)
    embeds_many(:impuestos, Impuesto)
  end

  def changeset(campo_adicional, params) do
    campo_adicional
    |> cast(params, [
      :codigo_principal,
      :codigo_auxiliar,
      :descripcion,
      :cantidad,
      :precio_unitario,
      :descuento,
      :precio_total_sin_impuesto
    ])
    |> validate_required([
      :codigo_principal,
      :descripcion,
      :cantidad,
      :precio_unitario,
      :descuento,
      :precio_total_sin_impuesto
    ])
    |> validate_length(:codigo_principal, max: 25)
    |> validate_length(:codigo_auxiliar, max: 25)
    |> validate_length(:descripcion, max: 300)
    |> cast_embed(:detalles_adicionales, required: false, with: &DetAdicional.changeset/2)
    |> cast_embed(:impuestos, required: true, with: &Impuesto.changeset/2)
  end

  def to_doc(%Detalle{} = detalle, decimals \\ @decimals) do
    fields =
      Enum.reject(
        [
          {:codigoPrincipal, nil, detalle.codigo_principal},
          if(detalle.codigo_auxiliar, do: {:codigoAuxiliar, nil, detalle.codigo_auxiliar}),
          {:descripcion, nil, detalle.descripcion},
          {:cantidad, nil, detalle.cantidad |> Decimal.round(6) |> Decimal.to_string(:normal)},
          {:precioUnitario, nil, detalle.precio_unitario |> Decimal.round(6) |> Decimal.to_string(:normal)},
          {:descuento, nil, detalle.descuento |> Decimal.round(decimals) |> Decimal.to_string(:normal)},
          {:precioTotalSinImpuesto, nil,
           detalle.precio_total_sin_impuesto |> Decimal.round(decimals) |> Decimal.to_string(:normal)},
          if(detalle.detalles_adicionales != [] and detalle.detalles_adicionales != nil,
            do: {:detallesAdicionales, nil, detalles_adicionales_to_doc(detalle.detalles_adicionales)}
          ),
          {:impuestos, nil, impuestos_to_doc(detalle.impuestos)}
        ],
        &is_nil/1
      )

    {:detalle, nil, fields}
  end

  def to_xml(%Detalle{} = detalle) do
    detalle
    |> to_doc()
    |> XmlBuilder.generate()
  end

  def detalles_adicionales_to_doc(detalles_adicionales) do
    Enum.map(detalles_adicionales, fn det_adicional -> DetAdicional.to_doc(det_adicional) end)
  end

  defp impuestos_to_doc(impuestos) do
    Enum.map(impuestos, fn impuesto -> Impuesto.to_doc(impuesto) end)
  end
end
