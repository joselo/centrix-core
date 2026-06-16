defmodule CentrixCore.Dataset.ClaveAcceso.DigitoVerificadorTest do
  use ExUnit.Case

  alias CentrixCore.Dataset.ClaveAcceso.DigitoVerificador

  setup do
    {:ok, fecha_emision} = Date.new(2020, 2, 3)

    changes = %{
      fecha_emision: fecha_emision,
      tipo_comprobante: 1,
      ruc: "1234567890001",
      ambiente: 1,
      estab: 1,
      pto_emi: 1,
      secuencial: 1,
      codigo: 1,
      tipo_emision: 1
    }

    {:ok, changes: changes}
  end

  test "changes_to_string", %{changes: changes} do
    key_str = DigitoVerificador.changes_to_string(changes)

    assert key_str == "030220200112345678900011001001000000001000000011"
    assert String.length(key_str) == 48
  end

  test "mod11 with string" do
    mod11 = DigitoVerificador.mod11("41261533")
    assert mod11 == 6
  end

  test "generate", %{changes: changes} do
    access_key_expected = "0302202001123456789000110010010000000010000000112"

    assert DigitoVerificador.generate(changes) == access_key_expected
  end
end
