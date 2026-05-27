defmodule BillingCore.Xbes.SignedInfo.Properties do
  @moduledoc false

  alias BillingCore.Xbes.Util

  def digest(cfg) do
    cfg
    |> get()
    |> XmlBuilder.generate(format: :none)
    |> Util.digest()
  end

  def get(cfg, xmlns \\ true) do
    id = "Signature#{cfg.signature_number}-SignedProperties#{cfg.signed_properties_number}"
    {attrs, close_tag} = Util.attrs(id, xmlns)

    {:"etsi:SignedProperties", attrs,
     [
       {:"etsi:SignedSignatureProperties", nil,
        [
          {:"etsi:SigningTime", nil, cfg.signing_time},
          {:"etsi:SigningCertificate", nil,
           [
             {:"etsi:Cert", nil,
              [
                {:"etsi:CertDigest", nil,
                 [
                   {:"ds:DigestMethod", %{Algorithm: "http://www.w3.org/2000/09/xmldsig#sha1"}, close_tag},
                   {:"ds:DigestValue", nil, cfg.crt_digest}
                 ]},
                {:"etsi:IssuerSerial", nil,
                 [
                   {:"ds:X509IssuerName", nil, cfg.crt_issuer_name},
                   {:"ds:X509SerialNumber", nil, cfg.crt_serial_number}
                 ]}
              ]}
           ]}
        ]},
       {:"etsi:SignedDataObjectProperties", nil,
        [
          {:"etsi:DataObjectFormat", %{ObjectReference: "#Reference-ID-#{cfg.reference_id_number}"},
           [
             {:"etsi:Description", nil, cfg.signed_data_description},
             {:"etsi:MimeType", nil, "text/xml"}
           ]}
        ]}
     ]}
  end
end
