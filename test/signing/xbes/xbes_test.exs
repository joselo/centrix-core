defmodule CentrixCore.XbesTest do
  use ExUnit.Case

  alias CentrixCore.Xbes.Cfg
  alias CentrixCore.Xbes.P12.Certificate
  alias CentrixCore.Xbes.P12.Key
  alias CentrixCore.Xbes.Signature
  alias CentrixCore.Xbes.SignedInfo
  alias CentrixCore.Xbes.SignedInfo.Doc
  alias CentrixCore.Xbes.SignedInfo.KeyInfo
  alias CentrixCore.Xbes.SignedInfo.Properties

  setup do
    xml =
      "test/fixtures/xml.xml"
      |> File.read!()
      |> String.replace("</factura>\n", "</factura>")

    crt_pem = File.read!("test/fixtures/cert.pem")
    key_pem = File.read!("test/fixtures/key.pem")

    crt = Certificate.build(crt_pem)
    key_index = crt.key_index

    signing_time = "2020-07-18T14:47:45-07:00"

    cfg = %Cfg{
      certificate_number: 1_631_523,
      signature_number: 753_013,
      signed_properties_number: 525_548,
      signed_info_number: 180_674,
      signed_properties_id_number: 374_965,
      reference_id_number: 995_332,
      signature_value_number: 106_482,
      object_number: 458_683,
      signing_time: signing_time,
      signed_data_description: "contenido comprobante",
      crt_digest: crt.digest,
      crt_issuer_name: crt.issuer_name,
      crt_serial_number: crt.serial_number,
      crt_modulus: crt.modulus,
      crt_exponent: crt.exponent,
      crt_x509: crt.x509
    }

    {:ok, xml: xml, cfg: cfg, crt_pem: crt_pem, key_pem: key_pem, signing_time: signing_time, key_index: key_index}
  end

  test "full test", %{xml: xml, cfg: cfg, key_pem: key_pem, key_index: key_index} do
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
    signature_value = Key.sign_with_pem(signed_info_digest, key_pem, key_index)

    # Signature
    signature =
      cfg
      |> Signature.get(signed_info, signature_value, key_info, properties)
      |> XmlBuilder.generate(format: :none)

    # Output
    CentrixCore.Xbes.merge(xml, signature)
  end

  test "sign", %{
    xml: xml,
    cfg: _cfg,
    crt_pem: crt_pem,
    key_pem: key_pem,
    signing_time: signing_time
  } do
    # CentrixCore.XbesMock
    # |> expect(:get_cfg, fn _crt, _signing_time, _signed_data_description -> cfg end)

    assert {:ok, _signed} = CentrixCore.Xbes.sign(xml, crt_pem, key_pem, signing_time)
  end
end
