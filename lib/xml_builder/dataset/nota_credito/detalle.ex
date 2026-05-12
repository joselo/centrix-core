defmodule BillingCore.Dataset.NotaCredito.Detalle do
  @moduledoc false

  @decimals BillingCore.decimals()

  alias BillingCore.Dataset.NotaCredito.{DetAdicional, Impuesto}

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:codigo_interno, :string)
    field(:codigo_adicional, :string)
    field(:descripcion, :string)
    field(:cantidad, :float)
    field(:precio_unitario, :float)
    field(:descuento, :float)
    field(:precio_total_sin_impuesto, :float)

    embeds_many(:detalles_adicionales, DetAdicional)
    embeds_many(:impuestos, Impuesto)
  end

  def changeset(campo_adicional, params) do
    campo_adicional
    |> cast(params, [
      :codigo_interno,
      :codigo_adicional,
      :descripcion,
      :cantidad,
      :precio_unitario,
      :descuento,
      :precio_total_sin_impuesto
    ])
    |> validate_required([
      :codigo_interno,
      :codigo_adicional,
      :descripcion,
      :cantidad,
      :precio_unitario,
      :descuento,
      :precio_total_sin_impuesto
    ])
    |> cast_embed(:detalles_adicionales, with: &DetAdicional.changeset/2)
    |> cast_embed(:impuestos, required: true, with: &Impuesto.changeset/2)
  end

  def to_doc(%BillingCore.Dataset.NotaCredito.Detalle{} = detalle, decimals \\ @decimals) do
    fields =
      [
        {:codigoInterno, nil, detalle.codigo_interno},
        {:codigoAdicional, nil, detalle.codigo_adicional},
        {:descripcion, nil, detalle.descripcion},
        {:cantidad, nil, :erlang.float_to_binary(detalle.cantidad, decimals: 6)},
        {:precioUnitario, nil, :erlang.float_to_binary(detalle.precio_unitario, decimals: 6)},
        {:descuento, nil, :erlang.float_to_binary(detalle.descuento, decimals: decimals)},
        {:precioTotalSinImpuesto, nil,
         :erlang.float_to_binary(detalle.precio_total_sin_impuesto, decimals: decimals)},
        if(detalle.detalles_adicionales != [] and detalle.detalles_adicionales != nil,
          do: {:detallesAdicionales, nil, detalles_adicionales_to_doc(detalle.detalles_adicionales)}
        ),
        {:impuestos, nil, impuestos_to_doc(detalle.impuestos)}
      ]
      |> Enum.reject(&is_nil/1)

    {:detalle, nil, fields}
  end

  def to_xml(%BillingCore.Dataset.NotaCredito.Detalle{} = detalle) do
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
