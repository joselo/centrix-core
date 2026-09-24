defmodule CentrixCore.Xbes.P12.Certificate do
  @moduledoc false

  def build(pem_file) do
    {pem, index} = pem_decode(pem_file)
    rsa = public_key_from_pem(pem)

    %{
      issuer_name: issuer_name_from_pem(pem_file),
      x509: x509_from_pem(pem),
      serial_number: serial_number_from_pem(pem),
      digest: digest_from_pem(pem),
      exponent: exponent_from_rsa(rsa),
      modulus: modulus_from_rsa(rsa),
      key_index: index
    }
  end

  def x509_from_pem(pem) do
    pem
    |> List.wrap()
    |> :public_key.pem_encode()
    |> String.replace("-----BEGIN CERTIFICATE-----\n", "")
    |> String.replace("\n-----END CERTIFICATE-----\n\n", "")
  end

  def serial_number_from_pem(pem) do
    pem
    |> :public_key.pem_entry_decode()
    |> elem(1)
    |> elem(2)
  end

  def digest_from_pem(pem) do
    ans1_entry = :public_key.pem_entry_decode(pem)

    ans1_type = elem(ans1_entry, 0)
    der = :public_key.der_encode(ans1_type, ans1_entry)

    :sha
    |> :crypto.hash(der)
    |> Base.encode64()
  end

  def exponent_from_rsa(rsa) do
    rsa
    |> elem(2)
    |> :binary.encode_unsigned()
    |> Base.encode64()
  end

  def modulus_from_rsa(rsa) do
    rsa
    |> elem(1)
    |> :binary.encode_unsigned()
    |> Base.encode64()
  end

  # Formats the issuer the same way `openssl x509 -issuer` prints it
  # (e.g. "C=EC, O=SECURITY DATA S.A. 2, OU=..., CN=..."), but by reading the
  # certificate's own Issuer Name structure instead of parsing openssl's
  # text output — nothing here shells out to `openssl` any more (see
  # CentrixCore.Signing.Pkcs12).
  def issuer_name_from_pem(pem_file) do
    {pem, _index} = pem_decode(pem_file)

    issuer =
      pem
      |> :public_key.pem_entry_decode()
      |> elem(1)
      |> elem(4)

    format_name(issuer)
  end

  defp format_name({:rdnSequence, rdns}) do
    rdns
    |> Enum.map(fn [{:AttributeTypeAndValue, oid, value}] ->
      "#{attribute_type_short_name(oid)} = #{directory_string_to_binary(value)}"
    end)
    |> Enum.join(", ")
  end

  defp attribute_type_short_name({2, 5, 4, 3}), do: "CN"
  defp attribute_type_short_name({2, 5, 4, 5}), do: "serialNumber"
  defp attribute_type_short_name({2, 5, 4, 6}), do: "C"
  defp attribute_type_short_name({2, 5, 4, 7}), do: "L"
  defp attribute_type_short_name({2, 5, 4, 8}), do: "ST"
  defp attribute_type_short_name({2, 5, 4, 10}), do: "O"
  defp attribute_type_short_name({2, 5, 4, 11}), do: "OU"
  defp attribute_type_short_name(oid), do: inspect(oid)

  defp directory_string_to_binary({:utf8String, value}), do: value
  defp directory_string_to_binary({:printableString, value}), do: List.to_string(value)
  defp directory_string_to_binary({:teletexString, value}), do: List.to_string(value)
  defp directory_string_to_binary({:universalString, value}), do: List.to_string(value)
  defp directory_string_to_binary({:bmpString, value}), do: List.to_string(value)
  defp directory_string_to_binary(value) when is_list(value), do: List.to_string(value)
  defp directory_string_to_binary(value) when is_binary(value), do: value

  def validity_from_pem(pem) do
    validity =
      pem
      |> :public_key.pem_entry_decode()
      # Certificate
      |> elem(1)
      # :Validity
      |> elem(5)

    case validity do
      {:Validity, {:utcTime, not_before}, {:utcTime, not_after}} ->
        {:ok, not_before: not_before, not_after: not_after}

      _ ->
        {:error, "Error getting the certificate validity"}
    end
  end

  # It returns {cert, index}
  def pem_decode(pem) do
    pem
    |> :public_key.pem_decode()
    |> Enum.with_index()
    |> Enum.find(fn {crt, _} ->
      crt
      |> :public_key.pem_entry_decode()
      |> elem(1)
      |> elem(10)
      |> Enum.filter(&match?({:Extension, {2, 5, 29, 32}, _, _}, &1)) !== []
    end)
  end

  def public_key_from_pem(pem) do
    pem
    |> raw_public_key_from_pem()
    |> :public_key.pem_decode()
    |> hd()
    |> :public_key.pem_entry_decode()
  end

  def raw_public_key_from_pem(pem) do
    ans1_entry =
      pem
      |> :public_key.pem_entry_decode()
      |> elem(1)
      |> elem(7)

    :SubjectPublicKeyInfo
    |> :public_key.pem_entry_encode(ans1_entry)
    |> List.wrap()
    |> :public_key.pem_encode()
  end
end
