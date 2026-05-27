defmodule BillingCore.XbesBehaviour do
  @moduledoc false
  @callback get_cfg(String.t(), String.t(), String.t()) :: struct()
end

defmodule BillingCore.Xbes do
  @moduledoc false
  @behaviour BillingCore.XbesBehaviour

  alias BillingCore.Xbes.Cfg
  alias BillingCore.Xbes.P12.Certificate
  alias BillingCore.Xbes.P12.Key
  alias BillingCore.Xbes.Signature
  alias BillingCore.Xbes.SignedInfo
  alias BillingCore.Xbes.SignedInfo.Doc
  alias BillingCore.Xbes.SignedInfo.KeyInfo
  alias BillingCore.Xbes.SignedInfo.Properties

  def sign(xml, crt_pem, key_pem, signing_time, signed_data_description \\ "contenido comprobante")
      when is_bitstring(crt_pem) and is_bitstring(key_pem) and is_bitstring(xml) do
    crt = Certificate.build(crt_pem)

    cfg = config().get_cfg(crt, signing_time, signed_data_description)

    # Properties
    properties = Properties.get(cfg, false)
    properties_digest = Properties.digest(cfg)

    # KeyInfo
    key_info = KeyInfo.get(cfg, false)
    key_info_digest = KeyInfo.digest(cfg)

    # Document
    doc_digest = Doc.digest(xml)

    # Signed Info
    signed_info = SignedInfo.get(cfg, properties_digest, key_info_digest, doc_digest, false)
    signed_info_digest = SignedInfo.digest(cfg, properties_digest, key_info_digest, doc_digest)

    # Signature value
    signature_value = Key.sign_with_pem(signed_info_digest, key_pem, crt.key_index)

    # Signature
    signature =
      cfg
      |> Signature.get(signed_info, signature_value, key_info, properties)
      |> XmlBuilder.generate(format: :none)

    # Result Merged
    {:ok, BillingCore.Xbes.merge(xml, signature)}
  end

  def merge(doc, signature) do
    String.replace(doc, ~r/(<[^<]+)$/, "#{signature}\\1")
  end

  def get_cfg(crt, signing_time, signed_data_description) do
    %Cfg{
      certificate_number: get_id(),
      signature_number: get_id(),
      signed_properties_number: get_id(),
      signed_info_number: get_id(),
      signed_properties_id_number: get_id(),
      reference_id_number: get_id(),
      signature_value_number: get_id(),
      object_number: get_id(),
      signing_time: signing_time,
      signed_data_description: signed_data_description,
      crt_digest: crt.digest,
      crt_issuer_name: crt.issuer_name,
      crt_serial_number: crt.serial_number,
      crt_modulus: crt.modulus,
      crt_exponent: crt.exponent,
      crt_x509: crt.x509
    }
  end

  defp get_id do
    Enum.random(100_000..999_999)
  end

  defp config do
    __MODULE__
  end
end
