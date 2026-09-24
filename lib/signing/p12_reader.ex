defmodule CentrixCore.P12Reader do
  @moduledoc false

  alias CentrixCore.Signing.Pkcs12

  def read(path, password) do
    case read_cert(path, password) do
      {:ok, cert} ->
        case read_rsa(path, password) do
          {:ok, rsa} -> {:ok, cert, rsa}
          {:error, error} -> {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def get_metadata(path, password) do
    case read_cert(path, password) do
      {:ok, cert} ->
        case extract_expiration_date(cert) do
          {:ok, date} -> {:ok, %{expires_at: date}}
          {:error, reason} -> {:error, reason}
        end

      {:error, error} ->
        if String.contains?(error, "invalid password") do
          {:error, :invalid_password}
        else
          {:error, error}
        end
    end
  end

  defp extract_expiration_date(cert_pem) do
    [pem_entry] = :public_key.pem_decode(cert_pem)

    # Same access pattern as CentrixCore.Xbes.P12.Certificate.validity_from_pem/1:
    # pem_entry_decode/1 -> Certificate -> (elem 1) TBSCertificate -> (elem 5) Validity.
    validity = pem_entry |> :public_key.pem_entry_decode() |> elem(1) |> elem(5)

    case validity do
      {:Validity, _not_before, not_after} -> asn1_time_to_date(not_after)
      _ -> {:error, "Could not find expiration date in certificate"}
    end
  end

  defp asn1_time_to_date({:utcTime, time}) do
    <<yy::binary-2, mm::binary-2, dd::binary-2, _rest::binary>> = List.to_string(time)
    year = String.to_integer(yy)
    full_year = if year >= 50, do: 1900 + year, else: 2000 + year
    Date.new(full_year, String.to_integer(mm), String.to_integer(dd))
  end

  defp asn1_time_to_date({:generalTime, time}) do
    <<yyyy::binary-4, mm::binary-2, dd::binary-2, _rest::binary>> = List.to_string(time)
    Date.new(String.to_integer(yyyy), String.to_integer(mm), String.to_integer(dd))
  end

  defp asn1_time_to_date(_), do: {:error, "unsupported certificate time format"}

  def read_cert(path, password) do
    with {:ok, %{cert_der: cert_der}} <- extract(path, password) do
      {:ok, :public_key.pem_encode([{:Certificate, cert_der, :not_encrypted}])}
    end
  end

  def read_rsa(path, password) do
    with {:ok, %{key_der: key_der}} <- extract(path, password) do
      {:ok, :public_key.pem_encode([{:PrivateKeyInfo, key_der, :not_encrypted}])}
    end
  end

  defp extract(path, password) do
    case File.read(path) do
      {:ok, der} ->
        case Pkcs12.extract(der, password) do
          {:ok, result} -> {:ok, result}
          # A wrong password corrupts the padding/ASN.1 we then try to
          # decrypt and parse, which surfaces as a garbled-structure error
          # from deep inside the DER walker rather than a clean reason — same
          # end-user-visible case openssl's own "invalid password" used to
          # cover, and just as unspecific about *why* parsing failed.
          {:error, _reason} -> {:error, "invalid password"}
        end

      {:error, reason} ->
        {:error, "could not read #{path}: #{:file.format_error(reason)}"}
    end
  rescue
    _ -> {:error, "invalid password"}
  end
end
