defmodule BillingCore.Xbes.CertificateTest do
  use ExUnit.Case

  alias BillingCore.Xbes.P12.Certificate

  setup do
    pem_file = File.read!("test/fixtures/cert.pem")
    {pem, _} = Certificate.pem_decode(pem_file)

    {:ok, pem_file: pem_file, pem: pem}
  end

  test "issuer_name_from_pem with bank data pem file", %{pem_file: pem_file} do
    # expected_result =
    #   "L=QUITO, CN=AC BANCO CENTRAL DEL ECUADOR, " <>
    #   "OU=ENTIDAD DE CERTIFICACION DE INFORMACION-ECIBCE, " <>
    #   "O=BANCO CENTRAL DEL ECUADOR, C=EC"

    expected_result =
      "C = EC, O = BANCO CENTRAL DEL ECUADOR, OU = ENTIDAD DE CERTIFICACION DE INFORMACION-ECIBCE, L = QUITO, CN = AC BANCO CENTRAL DEL ECUADOR"

    result =
      pem_file
      |> Certificate.issuer_name_from_pem()
      |> String.split(", ")
      |> Enum.all?(fn value ->
        String.contains?(expected_result, value)
      end)

    assert result

    # result =
    #   pem_file
    #   |> Certificate.issuer_name_from_pem()
    #   |> String.split(", ")
    #   |> Enum.all?(fn value ->
    #     String.contains?(expected_result, value)
    #   end)

    # assert result
  end

  ## Se comento ya que el certificado es informacion sensible y no se incluye en el codigo
  # test "issuer_name_from_pem with security data pem file" do
  #   pem_file = File.read!("test/fixtures/security-data.crt.pem")
  #   {pem, _} = Certificate.pem_decode(pem_file)

  #   expected_result =
  #     "C=EC, CN=AUTORIDAD DE CERTIFICACION SUBCA-2 SECURITY DATA, " <>
  #     "O=SECURITY DATA S.A. 2, OU=ENTIDAD DE CERTIFICACION DE INFORMACION"

  #   assert Certificate.issuer_name_from_pem(pem) == expected_result
  # end

  test "pem_decode", %{pem_file: pem_file} do
    [_, _, _, expected_cert] = :public_key.pem_decode(pem_file)

    {cert, index} = Certificate.pem_decode(pem_file)

    assert cert == expected_cert
    assert index == 3
  end

  test "validity_from_pem", %{pem: pem} do
    assert {:ok, not_before: _, not_after: _} = Certificate.validity_from_pem(pem)
  end
end
