defmodule BillingCore.Xbes.SignedInfo do
  @moduledoc false

  alias BillingCore.Xbes.Util

  def digest(cfg, properties_digest, key_info_digest, doc_digest) do
    cfg
    |> get(properties_digest, key_info_digest, doc_digest)
    |> XmlBuilder.generate(format: :none)
  end

  def get(cfg, properties_digest, key_info_digest, doc_digest, xmlns \\ true) do
    id = "Signature-SignedInfo#{cfg.signed_info_number}"
    {attrs, close_tag} = Util.attrs(id, xmlns)

    {:"ds:SignedInfo", attrs,
     [
       {:"ds:CanonicalizationMethod", %{Algorithm: "http://www.w3.org/TR/2001/REC-xml-c14n-20010315"}, close_tag},
       {:"ds:SignatureMethod", %{Algorithm: "http://www.w3.org/2000/09/xmldsig#rsa-sha1"}, close_tag},
       {:"ds:Reference",
        [
          Id: "SignedPropertiesID#{cfg.signed_properties_id_number}",
          Type: "http://uri.etsi.org/01903#SignedProperties",
          URI: "#Signature#{cfg.signature_number}-SignedProperties#{cfg.signed_properties_number}"
        ],
        [
          {:"ds:DigestMethod", %{Algorithm: "http://www.w3.org/2000/09/xmldsig#sha1"}, close_tag},
          {:"ds:DigestValue", nil, properties_digest}
        ]},
       {:"ds:Reference", %{URI: "#Certificate#{cfg.certificate_number}"},
        [
          {:"ds:DigestMethod", %{Algorithm: "http://www.w3.org/2000/09/xmldsig#sha1"}, close_tag},
          {:"ds:DigestValue", nil, key_info_digest}
        ]},
       {:"ds:Reference", [Id: "Reference-ID-#{cfg.reference_id_number}", URI: "#comprobante"],
        [
          {:"ds:Transforms", nil,
           [
             {:"ds:Transform", %{Algorithm: "http://www.w3.org/2000/09/xmldsig#enveloped-signature"}, close_tag}
           ]},
          {:"ds:DigestMethod", %{Algorithm: "http://www.w3.org/2000/09/xmldsig#sha1"}, close_tag},
          {:"ds:DigestValue", nil, doc_digest}
        ]}
     ]}
  end
end
