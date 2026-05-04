defmodule BillingCore.Dataset.GuiaRemision.InfoGuiaRemision do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:dir_establecimiento, :string)
    field(:dir_partida, :string)
    field(:razon_social_transportista, :string)
    field(:tipo_identificacion_transportista, :string)
    field(:ruc_transportista, :string)
    field(:rise, :string)
    field(:obligado_contabilidad, :string)
    field(:contribuyente_especial, :string)
    field(:fecha_ini_transporte, :date)
    field(:fecha_fin_transporte, :date)
    field(:placa, :string)
  end

  def changeset(info_guia, params \\ %{}) do
    info_guia
    |> cast(params, [
      :dir_establecimiento,
      :dir_partida,
      :razon_social_transportista,
      :tipo_identificacion_transportista,
      :ruc_transportista,
      :rise,
      :obligado_contabilidad,
      :contribuyente_especial,
      :fecha_ini_transporte,
      :fecha_fin_transporte,
      :placa
    ])
    |> validate_required([
      :dir_partida,
      :razon_social_transportista,
      :tipo_identificacion_transportista,
      :ruc_transportista,
      :fecha_ini_transporte,
      :fecha_fin_transporte,
      :placa
    ])
  end

  def to_doc(%BillingCore.Dataset.GuiaRemision.InfoGuiaRemision{} = info) do
    doc =
      [
        {:dirPartida, nil, info.dir_partida},
        {:razonSocialTransportista, nil, info.razon_social_transportista},
        {:tipoIdentificacionTransportista, nil, info.tipo_identificacion_transportista},
        {:rucTransportista, nil, info.ruc_transportista},
        {:fechaIniTransporte, nil, format_fecha_emision(info.fecha_ini_transporte)},
        {:fechaFinTransporte, nil, format_fecha_emision(info.fecha_fin_transporte)},
        {:placa, nil, info.placa}
      ]
      |> add_dir_establecimiento(info)
      |> add_rise(info)
      |> add_obligado_contabilidad(info)
      |> add_contribuyente_especial(info)

    {
      :infoGuiaRemision,
      nil,
      doc
    }
  end

  def to_xml(%BillingCore.Dataset.GuiaRemision.InfoGuiaRemision{} = info) do
    to_doc(info)
    |> XmlBuilder.generate()
  end

  defp format_fecha_emision(%Date{} = fecha_emision) do
    Timex.format!(fecha_emision, "%d/%m/%Y", :strftime)
  end

  defp add_dir_establecimiento(doc, %{dir_establecimiento: nil}), do: doc

  defp add_dir_establecimiento(doc, %{dir_establecimiento: dir_establecimiento}) do
    List.insert_at(doc, 0, {:dirEstablecimiento, nil, dir_establecimiento})
  end

  defp add_rise(doc, %{rise: nil}), do: doc

  defp add_rise(doc, %{rise: rise}) do
    index = Enum.find_index(doc, fn {tag, _, _} -> tag == :rucTransportista end)
    List.insert_at(doc, index + 1, {:rise, nil, rise})
  end

  defp add_obligado_contabilidad(doc, %{obligado_contabilidad: nil}), do: doc

  defp add_obligado_contabilidad(doc, %{obligado_contabilidad: obligado_contabilidad}) do
    index =
      case Enum.find_index(doc, fn {tag, _, _} -> tag == :rise end) do
        nil -> Enum.find_index(doc, fn {tag, _, _} -> tag == :rucTransportista end)
        i -> i
      end

    List.insert_at(doc, index + 1, {:obligadoContabilidad, nil, obligado_contabilidad})
  end

  defp add_contribuyente_especial(doc, %{contribuyente_especial: nil}), do: doc

  defp add_contribuyente_especial(doc, %{contribuyente_especial: contribuyente_especial}) do
    index =
      case Enum.find_index(doc, fn {tag, _, _} -> tag == :obligadoContabilidad end) do
        nil ->
          case Enum.find_index(doc, fn {tag, _, _} -> tag == :rise end) do
            nil -> Enum.find_index(doc, fn {tag, _, _} -> tag == :rucTransportista end)
            i -> i
          end
        i -> i
      end

    List.insert_at(doc, index + 1, {:contribuyenteEspecial, nil, contribuyente_especial})
  end
end
