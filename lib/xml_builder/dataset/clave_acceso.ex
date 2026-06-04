defmodule BillingCore.Dataset.ClaveAcceso do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:fecha_emision, :date)
    field(:tipo_comprobante, :integer)
    field(:ruc, :string)
    field(:ambiente, :integer)
    field(:pto_emi, :integer)
    field(:estab, :integer)
    field(:secuencial, :integer)
    field(:codigo, :integer)
    field(:tipo_emision, :integer)
  end

  def changeset(clave, params \\ %{}) do
    clave
    |> cast(params, [
      :fecha_emision,
      :tipo_comprobante,
      :ruc,
      :ambiente,
      :pto_emi,
      :estab,
      :secuencial,
      :codigo,
      :tipo_emision
    ])
    |> validate_required([
      :fecha_emision,
      :tipo_comprobante,
      :ruc,
      :ambiente,
      :pto_emi,
      :estab,
      :secuencial,
      :codigo,
      :tipo_emision
    ])
    |> validate_number(:tipo_comprobante, greater_than_or_equal_to: 1, less_than: 100)
    |> validate_length(:ruc, is: 13)
    |> validate_inclusion(:ambiente, [1, 2])
    |> validate_number(:pto_emi, greater_than_or_equal_to: 0, less_than: 1000)
    |> validate_number(:estab, greater_than_or_equal_to: 0, less_than: 1000)
    |> validate_number(:secuencial, greater_than_or_equal_to: 1, less_than: 1_000_000_000)
    |> validate_number(:codigo, greater_than_or_equal_to: 0, less_than: 100_000_000)
    |> validate_inclusion(:tipo_emision, [1])
  end
end
