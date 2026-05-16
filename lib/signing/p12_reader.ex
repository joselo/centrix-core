defmodule BillingCore.P12Reader do
  @moduledoc false

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
        cond do
          String.contains?(error, "invalid password") -> {:error, :invalid_password}
          true -> {:error, error}
        end
    end
  end

  defp extract_expiration_date(cert_pem) do
    temp_path = Path.join(System.tmp_dir!(), "cert_#{:erlang.unique_integer([:positive])}.pem")
    File.write!(temp_path, cert_pem)

    case System.cmd("openssl", ["x509", "-enddate", "-noout", "-in", temp_path]) do
      {output, 0} ->
        File.rm(temp_path)
        parse_expiration_date(output)

      {error, _} ->
        File.rm(temp_path)
        {:error, error}
    end
  end

  defp parse_expiration_date(output) do
    case Regex.run(~r/notAfter=(.*)/, output) do
      [_, date_str] ->
        normalized_date = String.trim(date_str) |> String.replace(~r/\s+/, " ")

        case Timex.parse(normalized_date, "{Mshort} {D} {h24}:{m}:{s} {YYYY} GMT") do
          {:ok, datetime} -> {:ok, NaiveDateTime.to_date(datetime)}
          {:error, _} -> {:error, "Could not parse date: #{normalized_date}"}
        end

      _ ->
        {:error, "Could not find expiration date in openssl output"}
    end
  end

  def read_cert(path, password) do
    options = [
      "pkcs12",
      "-in",
      path,
      "-clcerts",
      "-nokeys",
      "-passin",
      "pass:#{password}"
    ]

    options = legacy_options(options)

    case System.cmd("openssl", options, stderr_to_stdout: true) do
      {cert, 0} -> {:ok, cert}
      {error, 1} -> {:error, error}
    end
  end

  def read_rsa(path, password) do
    options = [
      "pkcs12",
      "-in",
      path,
      "-nocerts",
      "-nodes",
      "-passin",
      "pass:#{password}"
    ]

    options = legacy_options(options)

    case System.cmd("openssl", options, stderr_to_stdout: true) do
      {rsa, 0} -> {:ok, rsa}
      {error, 1} -> {:error, error}
    end
  end

  defp legacy_options(options) do
    {major, minor, _patch} = openssl_version()

    if major > 3 or (major == 3 and minor >= 0) do
      options ++ ["-legacy"]
    else
      options
    end
  end

  defp openssl_version do
    {output, 0} = System.cmd("openssl", ["version"])

    case Regex.run(~r/OpenSSL (\d+)\.(\d+)\.(\d+)/, output) do
      [_, major, minor, patch] ->
        {String.to_integer(major), String.to_integer(minor), String.to_integer(patch)}

      _ ->
        {0, 0, 0}
    end
  end
end
