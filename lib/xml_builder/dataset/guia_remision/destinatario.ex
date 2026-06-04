defmodule BillingCore.Dataset.GuiaRemision.Destinatario do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BillingCore.Dataset.GuiaRemision.Destinatario
  alias BillingCore.Dataset.GuiaRemision.Detalle

  embedded_schema do
    field(:identificacion_destinatario, :string)
    field(:razon_social_destinatario, :string)
    field(:dir_destinatario, :string)
    field(:motivo_traslado, :string)
    field(:doc_aduanero_unico, :string)
    field(:cod_estab_destino, :string)
    field(:ruta, :string)
    field(:cod_doc_sustento, :string)
    field(:num_doc_sustento, :string)
    field(:num_aut_doc_sustento, :string)
    field(:fecha_emision_doc_sustento, :date)

    embeds_many(:detalles, Detalle)
  end

  def changeset(destinatario, params \\ %{}) do
    destinatario
    |> cast(params, [
      :identificacion_destinatario,
      :razon_social_destinatario,
      :dir_destinatario,
      :motivo_traslado,
      :doc_aduanero_unico,
      :cod_estab_destino,
      :ruta,
      :cod_doc_sustento,
      :num_doc_sustento,
      :num_aut_doc_sustento,
      :fecha_emision_doc_sustento
    ])
    |> validate_required([
      :identificacion_destinatario,
      :razon_social_destinatario,
      :dir_destinatario,
      :motivo_traslado
    ])
    |> cast_embed(:detalles, required: true, with: &Detalle.changeset/2)
  end

  def to_doc(%Destinatario{} = destinatario) do
    doc =
      [
        {:identificacionDestinatario, nil, destinatario.identificacion_destinatario},
        {:razonSocialDestinatario, nil, destinatario.razon_social_destinatario},
        {:dirDestinatario, nil, destinatario.dir_destinatario},
        {:motivoTraslado, nil, destinatario.motivo_traslado}
      ]
      |> add_doc_aduanero_unico(destinatario)
      |> add_cod_estab_destino(destinatario)
      |> add_ruta(destinatario)
      |> add_cod_doc_sustento(destinatario)
      |> add_num_doc_sustento(destinatario)
      |> add_num_aut_doc_sustento(destinatario)
      |> add_fecha_emision_doc_sustento(destinatario)
      |> add_detalles(destinatario)

    {
      :destinatario,
      nil,
      doc
    }
  end

  def to_xml(%Destinatario{} = destinatario) do
    destinatario
    |> to_doc()
    |> XmlBuilder.generate()
  end

  defp format_fecha_emision(%Date{} = fecha_emision) do
    Timex.format!(fecha_emision, "%d/%m/%Y", :strftime)
  end

  defp add_doc_aduanero_unico(doc, %{doc_aduanero_unico: nil}), do: doc

  defp add_doc_aduanero_unico(doc, %{doc_aduanero_unico: doc_aduanero_unico}) do
    List.insert_at(doc, -1, {:docAduaneroUnico, nil, doc_aduanero_unico})
  end

  defp add_cod_estab_destino(doc, %{cod_estab_destino: nil}), do: doc

  defp add_cod_estab_destino(doc, %{cod_estab_destino: cod_estab_destino}) do
    List.insert_at(doc, -1, {:codEstabDestino, nil, cod_estab_destino})
  end

  defp add_ruta(doc, %{ruta: nil}), do: doc

  defp add_ruta(doc, %{ruta: ruta}) do
    List.insert_at(doc, -1, {:ruta, nil, ruta})
  end

  defp add_cod_doc_sustento(doc, %{cod_doc_sustento: nil}), do: doc

  defp add_cod_doc_sustento(doc, %{cod_doc_sustento: cod_doc_sustento}) do
    List.insert_at(doc, -1, {:codDocSustento, nil, cod_doc_sustento})
  end

  defp add_num_doc_sustento(doc, %{num_doc_sustento: nil}), do: doc

  defp add_num_doc_sustento(doc, %{num_doc_sustento: num_doc_sustento}) do
    List.insert_at(doc, -1, {:numDocSustento, nil, num_doc_sustento})
  end

  defp add_num_aut_doc_sustento(doc, %{num_aut_doc_sustento: nil}), do: doc

  defp add_num_aut_doc_sustento(doc, %{num_aut_doc_sustento: num_aut_doc_sustento}) do
    List.insert_at(doc, -1, {:numAutDocSustento, nil, num_aut_doc_sustento})
  end

  defp add_fecha_emision_doc_sustento(doc, %{fecha_emision_doc_sustento: nil}), do: doc

  defp add_fecha_emision_doc_sustento(doc, %{fecha_emision_doc_sustento: fecha_emision_doc_sustento}) do
    List.insert_at(
      doc,
      -1,
      {:fechaEmisionDocSustento, nil, format_fecha_emision(fecha_emision_doc_sustento)}
    )
  end

  defp add_detalles(doc, %{detalles: detalles}) do
    detalles_doc = Enum.map(detalles, &Detalle.to_doc/1)
    doc ++ [{:detalles, nil, detalles_doc}]
  end
end
