defmodule BillingCore.Dataset.Factura.Detalle do
  @moduledoc false

  @decimals BillingCore.decimals()

  alias BillingCore.Dataset.Factura.{DetAdicional, Impuesto}

  use Ecto.Schema
  import Ecto.Changeset

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

  def to_doc(%BillingCore.Dataset.Factura.Detalle{} = detalle, decimals \\ @decimals) do
    fields =
      [
        {:codigoPrincipal, nil, detalle.codigo_principal},
        if(detalle.codigo_auxiliar, do: {:codigoAuxiliar, nil, detalle.codigo_auxiliar}),
        {:descripcion, nil, detalle.descripcion},
        {:cantidad, nil, Decimal.round(detalle.cantidad, 6) |> Decimal.to_string(:normal)},
        {:precioUnitario, nil, Decimal.round(detalle.precio_unitario, 6) |> Decimal.to_string(:normal)},
        {:descuento, nil, Decimal.round(detalle.descuento, decimals) |> Decimal.to_string(:normal)},
        {:precioTotalSinImpuesto, nil,
         Decimal.round(detalle.precio_total_sin_impuesto, decimals) |> Decimal.to_string(:normal)},
        if(detalle.detalles_adicionales != [] and detalle.detalles_adicionales != nil,
          do: {:detallesAdicionales, nil, detalles_adicionales_to_doc(detalle.detalles_adicionales)}
        ),
        {:impuestos, nil, impuestos_to_doc(detalle.impuestos)}
      ]
      |> Enum.reject(&is_nil/1)

    {:detalle, nil, fields}
  end

  def to_xml(%BillingCore.Dataset.Factura.Detalle{} = detalle) do
    to_doc(detalle)
    |> XmlBuilder.generate()
  end

  def detalles_adicionales_to_doc(detalles_adicionales) do
    detalles_adicionales
    |> Enum.map(fn det_adicional -> DetAdicional.to_doc(det_adicional) end)
  end

  defp impuestos_to_doc(impuestos) do
    impuestos
    |> Enum.map(fn impuesto -> Impuesto.to_doc(impuesto) end)
  end
end
