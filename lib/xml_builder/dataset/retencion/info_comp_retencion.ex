defmodule BillingCore.Dataset.Retencion.InfoCompRetencion do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:fecha_emision, :date)
    field(:dir_establecimiento, :string)
    field(:contribuyente_especial, :string)
    field(:obligado_contabilidad, :string)
    field(:tipo_identificacion_sujeto_retenido, :integer)
    field(:tipo_sujeto_retenido, :string)
    field(:parte_rel, :string)
    field(:razon_social_sujeto_retenido, :string)
    field(:identificacion_sujeto_retenido, :string)
    # mm/yyyy
    field(:periodo_fiscal, :string)
  end

  def changeset(info_comp_retencion, params \\ %{}) do
    info_comp_retencion
    |> cast(params, [
      :fecha_emision,
      :dir_establecimiento,
      :contribuyente_especial,
      :obligado_contabilidad,
      :tipo_identificacion_sujeto_retenido,
      :tipo_sujeto_retenido,
      :parte_rel,
      :razon_social_sujeto_retenido,
      :identificacion_sujeto_retenido,
      :periodo_fiscal
    ])
    |> validate_required([
      :fecha_emision,
      :tipo_identificacion_sujeto_retenido,
      :parte_rel,
      :razon_social_sujeto_retenido,
      :identificacion_sujeto_retenido,
      :periodo_fiscal
    ])
    |> validate_format(:periodo_fiscal, ~r/^(0[1-9]|1[0-2])\/\d{4}$/,
      message: "must be in mm/yyyy format"
    )
  end

  def to_doc(%BillingCore.Dataset.Retencion.InfoCompRetencion{} = info) do
    doc =
      [
        {:fechaEmision, nil, format_fecha_emision(info.fecha_emision)}
      ]
      |> add_dir_establecimiento(info)
      |> add_contribuyente_especial(info)
      |> add_obligado_contabilidad(info)
      |> add_tipo_identificacion(info)
      |> add_tipo_sujeto_retenido(info)
      |> add_parte_rel(info)
      |> add_razon_social(info)
      |> add_identificacion(info)
      |> add_periodo_fiscal(info)

    {
      :infoCompRetencion,
      nil,
      doc
    }
  end

  def to_xml(%BillingCore.Dataset.Retencion.InfoCompRetencion{} = info) do
    to_doc(info)
    |> XmlBuilder.generate()
  end

  defp format_fecha_emision(%Date{} = fecha_emision) do
    Timex.format!(fecha_emision, "%d/%m/%Y", :strftime)
  end

  defp add_dir_establecimiento(doc, %{dir_establecimiento: nil}), do: doc

  defp add_dir_establecimiento(doc, %{dir_establecimiento: dir_establecimiento}) do
    doc ++ [{:dirEstablecimiento, nil, dir_establecimiento}]
  end

  defp add_contribuyente_especial(doc, %{contribuyente_especial: nil}), do: doc

  defp add_contribuyente_especial(doc, %{contribuyente_especial: contribuyente_especial}) do
    doc ++ [{:contribuyenteEspecial, nil, contribuyente_especial}]
  end

  defp add_obligado_contabilidad(doc, %{obligado_contabilidad: nil}), do: doc

  defp add_obligado_contabilidad(doc, %{obligado_contabilidad: obligado_contabilidad}) do
    doc ++ [{:obligadoContabilidad, nil, obligado_contabilidad}]
  end

  defp add_tipo_identificacion(doc, %{tipo_identificacion_sujeto_retenido: tipo}) do
    doc ++
      [
        {:tipoIdentificacionSujetoRetenido, nil,
         tipo
         |> Integer.to_string()
         |> String.pad_leading(2, "0")}
      ]
  end

  defp add_tipo_sujeto_retenido(doc, %{tipo_sujeto_retenido: nil}), do: doc

  defp add_tipo_sujeto_retenido(doc, %{tipo_sujeto_retenido: tipo_sujeto_retenido}) do
    doc ++ [{:tipoSujetoRetenido, nil, tipo_sujeto_retenido}]
  end

  defp add_parte_rel(doc, %{parte_rel: parte_rel}) do
    doc ++ [{:parteRel, nil, parte_rel}]
  end

  defp add_razon_social(doc, %{razon_social_sujeto_retenido: razon_social}) do
    doc ++ [{:razonSocialSujetoRetenido, nil, razon_social}]
  end

  defp add_identificacion(doc, %{identificacion_sujeto_retenido: identificacion}) do
    doc ++ [{:identificacionSujetoRetenido, nil, identificacion}]
  end

  defp add_periodo_fiscal(doc, %{periodo_fiscal: periodo_fiscal}) do
    doc ++ [{:periodoFiscal, nil, periodo_fiscal}]
  end
end
