defmodule CentrixCore.Dataset.Factura.CampoAdicional do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias CentrixCore.Dataset.Factura.CampoAdicional

  embedded_schema do
    field(:nombre, :string)
    field(:valor, :string)
  end

  def changeset(campo_adicional, params) do
    campo_adicional
    |> cast(params, [:nombre, :valor])
    |> validate_required([:nombre, :valor])
  end

  def to_doc(%CampoAdicional{} = campo_adicional) do
    {
      :campoAdicional,
      %{nombre: campo_adicional.nombre},
      campo_adicional.valor
    }
  end

  def to_xml(%CampoAdicional{} = campo_adicional) do
    campo_adicional
    |> to_doc()
    |> XmlBuilder.generate()
  end
end
