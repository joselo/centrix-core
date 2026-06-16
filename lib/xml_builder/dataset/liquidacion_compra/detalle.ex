defmodule CentrixCore.Dataset.LiquidacionCompra.Detalle do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias CentrixCore.Dataset.Factura.DetAdicional
  alias CentrixCore.Dataset.Factura.Impuesto
  alias CentrixCore.Dataset.LiquidacionCompra.Detalle

  @decimals CentrixCore.decimals()
  @quantity_decimals 6

  embedded_schema do
    field(:codigo_principal, :string)
    field(:codigo_auxiliar, :string)
    field(:descripcion, :string)
    field(:unidad_medida, :string)
    field(:cantidad, :decimal)
    field(:precio_unitario, :decimal)
    field(:descuento, :decimal)
    field(:precio_total_sin_impuesto, :decimal)

    embeds_many(:detalles_adicionales, DetAdicional)
    embeds_many(:impuestos, Impuesto)
  end

  def changeset(detalle, params \\ %{}) do
    detalle
    |> cast(params, [
      :codigo_principal,
      :codigo_auxiliar,
      :descripcion,
      :unidad_medida,
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
      :precio_total_sin_impuesto
    ])
    |> cast_embed(:detalles_adicionales, with: &DetAdicional.changeset/2)
    |> cast_embed(:impuestos, required: true, with: &Impuesto.changeset/2)
  end

  def to_doc(%Detalle{} = detalle) do
    doc =
      [
        {:codigoPrincipal, nil, detalle.codigo_principal}
      ]
      |> add_codigo_auxiliar(detalle)
      |> add_descripcion(detalle)
      |> add_unidad_medida(detalle)
      |> add_cantidad(detalle)
      |> add_precio_unitario(detalle)
      |> add_descuento(detalle)
      |> add_precio_total_sin_impuesto(detalle)
      |> add_detalles_adicionales(detalle)
      |> add_impuestos(detalle)

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

  defp add_codigo_auxiliar(doc, %{codigo_auxiliar: nil}), do: doc

  defp add_codigo_auxiliar(doc, %{codigo_auxiliar: codigo_auxiliar}) do
    doc ++ [{:codigoAuxiliar, nil, codigo_auxiliar}]
  end

  defp add_descripcion(doc, %{descripcion: descripcion}) do
    doc ++ [{:descripcion, nil, descripcion}]
  end

  defp add_unidad_medida(doc, %{unidad_medida: nil}), do: doc

  defp add_unidad_medida(doc, %{unidad_medida: unidad_medida}) do
    doc ++ [{:unidadMedida, nil, unidad_medida}]
  end

  defp add_cantidad(doc, %{cantidad: cantidad}) do
    doc ++ [{:cantidad, nil, cantidad |> Decimal.round(@quantity_decimals) |> Decimal.to_string(:normal)}]
  end

  defp add_precio_unitario(doc, %{precio_unitario: precio_unitario}) do
    doc ++
      [
        {:precioUnitario, nil, precio_unitario |> Decimal.round(@quantity_decimals) |> Decimal.to_string(:normal)}
      ]
  end

  defp add_descuento(doc, %{descuento: nil}), do: doc

  defp add_descuento(doc, %{descuento: descuento}) do
    doc ++ [{:descuento, nil, descuento |> Decimal.round(@decimals) |> Decimal.to_string(:normal)}]
  end

  defp add_precio_total_sin_impuesto(doc, %{precio_total_sin_impuesto: precio_total_sin_impuesto}) do
    doc ++
      [
        {:precioTotalSinImpuesto, nil,
         precio_total_sin_impuesto |> Decimal.round(@decimals) |> Decimal.to_string(:normal)}
      ]
  end

  defp add_detalles_adicionales(doc, %{detalles_adicionales: []}), do: doc

  defp add_detalles_adicionales(doc, %{detalles_adicionales: detalles_adicionales}) do
    detalles_doc = Enum.map(detalles_adicionales, &DetAdicional.to_doc/1)
    doc ++ [{:detallesAdicionales, nil, detalles_doc}]
  end

  defp add_impuestos(doc, %{impuestos: []}), do: doc

  defp add_impuestos(doc, %{impuestos: impuestos}) do
    impuestos_doc = Enum.map(impuestos, &Impuesto.to_doc/1)
    doc ++ [{:impuestos, nil, impuestos_doc}]
  end
end
