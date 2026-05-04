# XAdES-BES Digital Signing — Implementation Reference

> **Intended audience:** AI agents and developers who need to understand, maintain, or extend the XML digital signing implementation in `BillingCore`. This document covers every module in `lib/signing/` with precise code-level detail.

---

## 1. Overview

The SRI requires all electronic documents to be **digitally signed** using the **XAdES-BES** (XML Advanced Electronic Signatures — Basic Electronic Signature) standard before submission. The signature is embedded directly inside the XML document as a `<ds:Signature>` block.

The implementation lives entirely under `lib/signing/`:

```
lib/signing/
├── p12_reader.ex              # Step 1: Extract PEM cert + RSA key from .p12 file
└── xbes/
    ├── cfg.ex                 # Shared configuration struct (IDs + cert data)
    ├── util.ex                # SHA1 digest helper + XML namespace attrs
    ├── xbes.ex                # Orchestrator: runs steps 2–7, injects signature
    ├── signature.ex           # Assembles final <ds:Signature> XML block
    ├── signed_info.ex         # Builds <ds:SignedInfo> with all digest references
    ├── p12/
    │   ├── certificate.ex     # Parses PEM cert → modulus, exponent, digest, serial, issuer, x509
    │   └── key.ex             # Signs data with RSA private key (SHA1withRSA)
    └── signed_info/
        ├── doc.ex             # C14N-canonicalizes + SHA1-digests the source XML document
        ├── key_info.ex        # Builds <ds:KeyInfo> + computes its digest
        └── properties.ex      # Builds <etsi:SignedProperties> + computes its digest
```

---

## 2. Public Entry Point

```elixir
# lib/signing.ex
BillingCore.Signing.sign(xml_string, p12_path, p12_password)
# Returns:
{:ok, signed_xml_string}
{:error, reason_string}
```

**Flow inside `Signing.sign/3`:**
1. Compute the current signing timestamp using `Timex.now("America/Guayaquil")` formatted as `"%FT%T%:z"` (ISO 8601 with timezone offset, e.g. `"2025-05-15T10:30:00-05:00"`).
2. Call `P12Reader.read/2` to extract PEM cert and RSA key strings.
3. Delegate to `Xbes.sign/5`.

---

## 3. Step 1 — P12 Certificate Reading (`lib/signing/p12_reader.ex`)

**Module:** `BillingCore.P12Reader`

The `.p12` (PKCS#12) certificate file is the digital identity issued by an Ecuadorian CA (e.g., BCE, Security Data). It contains both the certificate and the private key, protected by a password.

### How it works

Two separate `openssl pkcs12` CLI calls are made via `System.cmd/2`:

```elixir
# Extract PEM certificate (public)
openssl pkcs12 -in <path> -clcerts -nokeys -passin pass:<password> [-legacy]

# Extract RSA private key (unencrypted)
openssl pkcs12 -in <path> -nocerts -nodes -passin pass:<password> [-legacy]
```

**Returns:** `{:ok, cert_pem_string, rsa_pem_string}` or `{:error, error_string}`

### The `-legacy` flag

Many Ecuadorian P12 certificates use legacy encryption algorithms (`RC2-40-CBC`, `3DES`). OpenSSL 3.x dropped support for these by default. The code detects the OpenSSL version at runtime:

```elixir
defp openssl_version do
  {output, 0} = System.cmd("openssl", ["version"])
  # Parses "OpenSSL 3.1.4 ..." → {3, 1, 4}
end

defp legacy_options(options) do
  {major, minor, _} = openssl_version()
  if major > 3 or (major == 3 and minor >= 0) do
    options ++ ["-legacy"]   # Always add -legacy for OpenSSL 3.x
  else
    options
  end
end
```

> **Important:** Do not remove the `-legacy` flag check. Without it, OpenSSL 3 will silently fail to read most Ecuadorian P12 certificates.

---

## 4. Step 2 — Certificate Parsing (`lib/signing/xbes/p12/certificate.ex`)

**Module:** `BillingCore.Xbes.P12.Certificate`

Takes the PEM certificate string output from `openssl` and extracts the fields needed to build the XAdES signature blocks.

### `build/1` — main function

```elixir
Certificate.build(pem_file_string)
# Returns a map:
%{
  issuer_name:   "CN=..., O=..., C=EC",   # Formatted X.509 issuer DN
  x509:          "MIIFxxx...",             # Raw Base64 certificate (no PEM headers)
  serial_number: 12345678,                 # Integer serial from ASN.1
  digest:        "SHA1_base64==",          # SHA1 of DER-encoded cert, Base64
  exponent:      "AQAB",                   # RSA public exponent, Base64
  modulus:       "0nXk...",               # RSA modulus, Base64
  key_index:     0                         # Index of the signing cert in the PEM chain
}
```

### Key extraction details

| Field | Source | Method |
|---|---|---|
| `issuer_name` | PEM text output | Regex `~r/^issuer=(.+)$/m` on the raw openssl output; slashes replaced with `, ` |
| `x509` | ASN.1 decoded cert | Re-encoded to PEM, then PEM headers stripped → raw Base64 |
| `serial_number` | ASN.1 decoded cert | `elem(pem_entry_decode(pem), 1) \|> elem(2)` |
| `digest` | DER-encoded cert | `SHA1(:public_key.der_encode(type, entry))` → Base64 |
| `modulus` | RSA public key | `elem(rsa_key, 1)` → binary unsigned → Base64 |
| `exponent` | RSA public key | `elem(rsa_key, 2)` → binary unsigned → Base64 |
| `key_index` | PEM chain scan | Finds the cert entry that has an OID `2.5.29.32` extension (certificate policies) |

### Certificate selection (`pem_decode/1`)

The PEM output from openssl may contain a chain. The code picks the correct signing certificate by finding the entry with a **Certificate Policies** extension (`OID 2.5.29.32`):

```elixir
|> Enum.find(fn {crt, _} ->
  crt
  |> :public_key.pem_entry_decode()
  |> elem(1)
  |> elem(10)   # extensions list
  |> Enum.filter(&match?({:Extension, {2, 5, 29, 32}, _, _}, &1)) !== []
end)
```

---

## 5. Step 3 — Building the Configuration (`lib/signing/xbes/xbes.ex`)

**Module:** `BillingCore.Xbes` — function `get_cfg/3`

A `%Cfg{}` struct is built once and passed to all subsequent steps. It holds both the certificate data and 8 randomly generated IDs used to uniquely identify each XAdES XML element.

```elixir
%BillingCore.Xbes.Cfg{
  # 8 random 6-digit integers for XML element IDs
  certificate_number:         123456,
  signature_number:           234567,
  signed_properties_number:   345678,
  signed_info_number:         456789,
  signed_properties_id_number:567890,
  reference_id_number:        678901,
  signature_value_number:     789012,
  object_number:              890123,

  # From Signing.sign/3
  signing_time:               "2025-05-15T10:30:00-05:00",
  signed_data_description:    "contenido comprobante",

  # From Certificate.build/1
  crt_digest:      "SHA1 of DER cert, Base64",
  crt_issuer_name: "CN=..., O=..., C=EC",
  crt_serial_number: 12345678,
  crt_modulus:     "RSA modulus Base64",
  crt_exponent:    "RSA exponent Base64",
  crt_x509:        "raw cert Base64 (no PEM headers)"
}
```

> **Why random IDs?** XAdES requires each element to have a unique `Id` attribute. The IDs are not cryptographically significant — they just need to be unique within the document per signing operation. Using `Enum.random(100_000..999_999)` is sufficient.

---

## 6. Step 4 — Computing Digests (Three Inputs)

The `<ds:SignedInfo>` block must commit to exactly **three digests**:

| # | What | Module | Method |
|---|---|---|---|
| 1 | `<etsi:SignedProperties>` block | `Properties` | Generate XML → SHA1 → Base64 |
| 2 | `<ds:KeyInfo>` block | `KeyInfo` | Generate XML → SHA1 → Base64 |
| 3 | The source XML document | `Doc` | **C14N canonicalize** → SHA1 → Base64 |

### 6.1 Properties Digest (`lib/signing/xbes/signed_info/properties.ex`)

**Module:** `BillingCore.Xbes.SignedInfo.Properties`

Builds `<etsi:SignedProperties>` containing:
- `<etsi:SigningTime>` — the ISO 8601 signing timestamp
- `<etsi:SigningCertificate>` — SHA1 digest of the cert + issuer name + serial number
- `<etsi:DataObjectFormat>` — MIME type (`text/xml`) and description (`contenido comprobante`)

```xml
<etsi:SignedProperties Id="SignatureNNNNNN-SignedPropertiesNNNNNN"
    xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
    xmlns:etsi="http://uri.etsi.org/01903/v1.3.2#">
  <etsi:SignedSignatureProperties>
    <etsi:SigningTime>2025-05-15T10:30:00-05:00</etsi:SigningTime>
    <etsi:SigningCertificate>
      <etsi:Cert>
        <etsi:CertDigest>
          <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
          <ds:DigestValue>SHA1_of_cert_Base64==</ds:DigestValue>
        </etsi:CertDigest>
        <etsi:IssuerSerial>
          <ds:X509IssuerName>CN=..., O=..., C=EC</ds:X509IssuerName>
          <ds:X509SerialNumber>12345678</ds:X509SerialNumber>
        </etsi:IssuerSerial>
      </etsi:Cert>
    </etsi:SigningCertificate>
  </etsi:SignedSignatureProperties>
  <etsi:SignedDataObjectProperties>
    <etsi:DataObjectFormat ObjectReference="#Reference-ID-NNNNNN">
      <etsi:Description>contenido comprobante</etsi:Description>
      <etsi:MimeType>text/xml</etsi:MimeType>
    </etsi:DataObjectFormat>
  </etsi:SignedDataObjectProperties>
</etsi:SignedProperties>
```

**Digest computation:**
```elixir
get(cfg)                          # Build the XmlBuilder tuple tree
|> XmlBuilder.generate(format: :none)   # Serialize to XML string (no formatting)
|> Util.digest()                  # :crypto.hash(:sha, xml) |> Base64.encode64()
```

### 6.2 KeyInfo Digest (`lib/signing/xbes/signed_info/key_info.ex`)

**Module:** `BillingCore.Xbes.SignedInfo.KeyInfo`

Builds `<ds:KeyInfo>` containing:
- `<ds:X509Certificate>` — raw Base64 certificate
- `<ds:RSAKeyValue>` — RSA modulus and exponent (both Base64)

```xml
<ds:KeyInfo Id="CertificateNNNNNN"
    xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
    xmlns:etsi="http://uri.etsi.org/01903/v1.3.2#">
  <ds:X509Data>
    <ds:X509Certificate>MIIFxxx...</ds:X509Certificate>
  </ds:X509Data>
  <ds:KeyValue>
    <ds:RSAKeyValue>
      <ds:Modulus>0nXk...</ds:Modulus>
      <ds:Exponent>AQAB</ds:Exponent>
    </ds:RSAKeyValue>
  </ds:KeyValue>
</ds:KeyInfo>
```

**Digest:** same pattern — serialize XML → SHA1 → Base64.

### 6.3 Document Digest (`lib/signing/xbes/signed_info/doc.ex`)

**Module:** `BillingCore.Xbes.SignedInfo.Doc`

The source XML document **must be canonicalized** before digesting. Raw XML strings are not suitable because whitespace, attribute order, and namespace declarations can differ between implementations.

```elixir
def digest(xml) do
  xml
  |> SweetXml.parse(namespace_conformant: true, document: true)  # Parse to xmerl doc
  |> XmerlC14n.canonicalize!()    # Apply C14N (exclusive without comments)
  |> then(&:crypto.hash(:sha, &1))
  |> Base.encode64()
end
```

**Canonicalization algorithm:** `http://www.w3.org/TR/2001/REC-xml-c14n-20010315`  
**Library:** `xmerl_c14n ~> 0.2`

> The document being digested is the **original unsigned XML** (the full `<factura>` or `<notaCredito>` string). This ties the signature cryptographically to the document content.

---

## 7. Step 5 — Building `<ds:SignedInfo>` (`lib/signing/xbes/signed_info.ex`)

**Module:** `BillingCore.Xbes.SignedInfo`

`SignedInfo` is the data structure that is actually **signed with the private key**. It contains three `<ds:Reference>` elements, each pointing to one of the three digested inputs.

```xml
<ds:SignedInfo Id="Signature-SignedInfoNNNNNN"
    xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
    xmlns:etsi="http://uri.etsi.org/01903/v1.3.2#">

  <ds:CanonicalizationMethod
    Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>

  <ds:SignatureMethod
    Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>

  <!-- Reference 1: SignedProperties -->
  <ds:Reference
    Id="SignedPropertiesIDNNNNNN"
    Type="http://uri.etsi.org/01903#SignedProperties"
    URI="#SignatureNNNNNN-SignedPropertiesNNNNNN">
    <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
    <ds:DigestValue>BASE64_of_properties==</ds:DigestValue>
  </ds:Reference>

  <!-- Reference 2: KeyInfo -->
  <ds:Reference URI="#CertificateNNNNNN">
    <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
    <ds:DigestValue>BASE64_of_key_info==</ds:DigestValue>
  </ds:Reference>

  <!-- Reference 3: The source document -->
  <ds:Reference Id="Reference-ID-NNNNNN" URI="#comprobante">
    <ds:Transforms>
      <ds:Transform
        Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
    </ds:Transforms>
    <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
    <ds:DigestValue>BASE64_of_document==</ds:DigestValue>
  </ds:Reference>

</ds:SignedInfo>
```

**Key details:**
- `URI="#comprobante"` — matches the `id="comprobante"` attribute on the root XML element (`<factura id="comprobante" ...>`).
- The `enveloped-signature` transform tells verifiers to exclude the `<ds:Signature>` block itself when computing the document digest.
- `SignedInfo` is serialized with `format: :none` (no whitespace) before being fed to the signing step.

---

## 8. Step 6 — RSA Signing (`lib/signing/xbes/p12/key.ex`)

**Module:** `BillingCore.Xbes.P12.Key`

The serialized `<ds:SignedInfo>` string is signed with the RSA private key using **SHA1withRSA**:

```elixir
def sign_with_pem(value, pem_file, index) do
  pem = pem_decode(pem_file, index)       # Decode key at position `index` in PEM chain
  :public_key.sign(value, :sha, pem)      # RSA sign with SHA1
  |> Base.encode64()                       # → Base64 string
end
```

- `value` is the raw `<ds:SignedInfo>` XML string (not digested — `:public_key.sign` applies SHA1 internally).
- `index` comes from `Certificate.build/1` (`key_index`) — the position in the PEM chain that corresponds to the signing certificate.
- Algorithm URI: `http://www.w3.org/2000/09/xmldsig#rsa-sha1`

---

## 9. Step 7 — Assembling `<ds:Signature>` (`lib/signing/xbes/signature.ex`)

**Module:** `BillingCore.Xbes.Signature`

Assembles the complete `<ds:Signature>` block from all previously built pieces:

```elixir
def get(cfg, signed_info, signature_value, key_info, properties) do
  {:\"ds:Signature\", [xmlns:ds: ..., xmlns:etsi: ..., Id: "SignatureNNNNNN"],
   [
     signed_info,          # <ds:SignedInfo>
     {:\"ds:SignatureValue\", %{Id: "SignatureValueNNNNNN"}, signature_value},
     key_info,             # <ds:KeyInfo>
     {:\"ds:Object\", %{Id: "SignatureNNNNNN-ObjectNNNNNN"},
      [{:\"etsi:QualifyingProperties\", %{Target: "#SignatureNNNNNN"},
        [properties]}]}    # <etsi:SignedProperties>
   ]}
end
```

Full assembled structure:
```xml
<ds:Signature Id="SignatureNNNNNN"
    xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
    xmlns:etsi="http://uri.etsi.org/01903/v1.3.2#">
  <ds:SignedInfo>...</ds:SignedInfo>
  <ds:SignatureValue Id="SignatureValueNNNNNN">BASE64_RSA_SIGNATURE==</ds:SignatureValue>
  <ds:KeyInfo>...</ds:KeyInfo>
  <ds:Object Id="SignatureNNNNNN-ObjectNNNNNN">
    <etsi:QualifyingProperties Target="#SignatureNNNNNN">
      <etsi:SignedProperties>...</etsi:SignedProperties>
    </etsi:QualifyingProperties>
  </ds:Object>
</ds:Signature>
```

---

## 10. Step 8 — Injecting the Signature into the XML Document

**Module:** `BillingCore.Xbes` — function `merge/2`

The `<ds:Signature>` block is injected **inside** the root element of the source XML, just before its closing tag:

```elixir
def merge(doc, signature) do
  doc
  |> String.replace(~r/(<[^<]+)$/, "#{signature}\\1")
end
```

This regex finds the last `<...` substring in the document (which is the root closing tag, e.g., `</factura>`) and inserts the signature string before it.

**Result:**
```xml
<?xml version="1.0"?>
<factura id="comprobante" version="1.1.0">
  <infoTributaria>...</infoTributaria>
  <infoFactura>...</infoFactura>
  <detalles>...</detalles>
  <infoAdicional>...</infoAdicional>
  <ds:Signature Id="Signature...">
    ...
  </ds:Signature>
</factura>
```

---

## 11. Full Signing Orchestration (`lib/signing/xbes/xbes.ex`)

**Module:** `BillingCore.Xbes` — function `sign/5`

```elixir
def sign(xml, crt_pem, key_pem, signing_time, signed_data_description \\ "contenido comprobante")
```

Complete step-by-step flow:

```
1.  Certificate.build(crt_pem)
    → %{x509, modulus, exponent, digest, serial, issuer, key_index}

2.  Xbes.get_cfg(crt, signing_time, signed_data_description)
    → %Cfg{8 random IDs, signing_time, cert fields...}

3.  Properties.get(cfg, xmlns: false)        → SignedProperties XML tuple
    Properties.digest(cfg)                   → SHA1(serialize(SignedProperties)) → Base64

4.  KeyInfo.get(cfg, xmlns: false)           → KeyInfo XML tuple
    KeyInfo.digest(cfg)                      → SHA1(serialize(KeyInfo)) → Base64

5.  Doc.digest(xml)                          → SHA1(C14N(xml)) → Base64

6.  SignedInfo.get(cfg, prop_dig, key_dig, doc_dig, xmlns: false)  → SignedInfo XML tuple
    SignedInfo.digest(cfg, prop_dig, key_dig, doc_dig)
    → serialize(SignedInfo) as raw string (this is what gets signed)

7.  Key.sign_with_pem(signed_info_string, key_pem, key_index)
    → :public_key.sign(data, :sha, rsa_key) → Base64

8.  Signature.get(cfg, signed_info, sig_value, key_info, properties)
    → Complete <ds:Signature> XML tuple
    → XmlBuilder.generate(format: :none) → signature string

9.  Xbes.merge(xml, signature)
    → Injects <ds:Signature> before the closing root tag
    → {:ok, signed_xml_string}
```

---

## 12. XML Namespace Handling (`lib/signing/xbes/util.ex`)

**Module:** `BillingCore.Xbes.Util`

The `attrs/2` function controls whether namespace declarations are emitted on an element:

```elixir
def attrs(id_attr, xmlns_attr) do
  if xmlns_attr do
    # Used on root elements (<ds:Signature>, <ds:KeyInfo>, <etsi:SignedProperties>)
    attrs = [
      "xmlns:ds":   "http://www.w3.org/2000/09/xmldsig#",
      "xmlns:etsi": "http://uri.etsi.org/01903/v1.3.2#",
      Id: id_attr
    ]
    {attrs, ""}
  else
    # Used on inner elements when building for digest computation
    {[Id: id_attr], nil}
  end
end
```

**Why two modes?**
- When building blocks for **digest computation** (`xmlns: false`), namespaces are omitted to produce a compact canonical string.
- When building the **final injected signature** (`xmlns: true`), namespace declarations are included on the top-level elements so the XML remains well-formed after injection.

The second return value (`close_tag`) is `""` (empty string) when used as the content of a self-closing element (e.g., `<ds:DigestMethod .../>`), or `nil` for normal elements.

---

## 13. SHA1 Digest Utility (`lib/signing/xbes/util.ex`)

```elixir
def digest(value) do
  value
  |> hash()
  |> Base.encode64()
end

def hash(value) do
  :crypto.hash(:sha, value)
end
```

SHA1 is used throughout — both for element digests and for the RSA signing algorithm. This is required by the SRI XAdES-BES specification (SHA256 is not accepted).

---

## 14. Signing Algorithms & URIs Reference

| Purpose | Algorithm | URI |
|---|---|---|
| Canonicalization | C14N 1.0 (without comments) | `http://www.w3.org/TR/2001/REC-xml-c14n-20010315` |
| Digest (all) | SHA1 | `http://www.w3.org/2000/09/xmldsig#sha1` |
| Signature | RSA-SHA1 | `http://www.w3.org/2000/09/xmldsig#rsa-sha1` |
| Enveloped signature transform | XmlDSig Enveloped | `http://www.w3.org/2000/09/xmldsig#enveloped-signature` |
| XAdES namespace | ETSI TS 101 903 v1.3.2 | `http://uri.etsi.org/01903/v1.3.2#` |
| XMLDSig namespace | W3C XMLDSig | `http://www.w3.org/2000/09/xmldsig#` |
| SignedProperties type | ETSI | `http://uri.etsi.org/01903#SignedProperties` |

---

## 15. Dependencies Used in Signing

| Dependency | Role |
|---|---|
| `timex ~> 3.7` | Timezone-aware timestamp (`America/Guayaquil`, UTC-5, no DST) |
| `sweet_xml ~> 0.7` | Parses XML to `xmerl` document for C14N |
| `xmerl_c14n ~> 0.2` | XML canonicalization (C14N 1.0) |
| `xml_builder ~> 2.4` | Builds XAdES XML tuple trees → serialized strings |
| `:crypto` (OTP stdlib) | SHA1 hashing |
| `:public_key` (OTP stdlib) | PEM decoding, RSA signing, DER encoding |
| `openssl` (system CLI) | Reads P12 → extracts PEM cert + RSA key |

---

## 16. Testing

- **Test file:** `test/signing_test.exs`
- **Fixtures:**
  - `test/fixtures/file.p12` — test P12 certificate
  - `test/fixtures/cert.pem` — extracted PEM certificate
  - `test/fixtures/key.pem` — extracted RSA private key
  - `test/fixtures/xml.xml` — minimal unsigned XML
  - `test/fixtures/invoice_xml_signed.xml` — expected signed output
- **Environment variable required:** `TEST_P12_FILE_PASSWORD` (password for `file.p12`)

```bash
TEST_P12_FILE_PASSWORD="your_password" mix test test/signing_test.exs
```

---

## 17. Common Issues & Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `openssl` returns exit code 1 with "unsupported" error | P12 uses legacy encryption, OpenSSL 3 without `-legacy` | Already handled automatically by `P12Reader.legacy_options/1` |
| `Certificate.pem_decode/1` returns `nil` | No cert with OID `2.5.29.32` found in PEM chain | Verify the P12 is a valid signing certificate, not just a CA cert |
| Signature rejected by SRI with "firma inválida" | Namespace mismatch or wrong canonicalization | Ensure `Doc.digest/1` uses `XmerlC14n.canonicalize!` (not raw string hashing) |
| Different `clave_acceso` across runs | Random `codigo` in `ClaveAcceso` (unrelated to signing) | Signing IDs are also random — this is expected and correct |
| Wrong `key_index` causes signing failure | Multiple keys in PEM chain; wrong one picked | `Certificate.pem_decode/1` finds the cert with certificate policies extension; key uses same index |
