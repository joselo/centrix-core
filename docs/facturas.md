# Factura (Invoice) — Implementation Reference

> **Intended audience:** AI agents and developers maintaining or extending the invoice implementation in `CentrixCore`. This is a code-level reference for the Factura (`cod_doc = 01`) document type.

---

## 1. Overview

A **Factura** is Ecuador's primary SRI electronic invoice. The library handles the full lifecycle:
1. Validate params → Ecto changesets
2. Build XML → `XmlBuilder` library
3. Sign XML → XAdES-BES
4. Submit to SRI → SOAP `validarComprobante`
5. Poll authorization → SOAP `autorizacionComprobante`
6. (Optional) Parse authorized XML, generate barcode and PDF

---

## 2. Public Entry Points

```elixir
# Build XML
CentrixCore.XmlBuilder.build_invoice(params)
# => {:ok, [xml: xml_string, clave_acceso: "49-digit-key"]}
# => {:error, %Ecto.Changeset{}}

# Sign
CentrixCore.Signing.sign(xml_string, p12_path, p12_password)
# => {:ok, signed_xml_string}

# Send to SRI
CentrixCore.SriClient.send_document(signed_xml, environment)
# => {:ok, %{status: "RECIBIDA" | "DEVUELTA", response: soap_xml}}

# Poll authorization
CentrixCore.SriClient.is_authorized(clave_acceso, environment)
# => {:ok, %{status: "AUTORIZADO" | "NO AUTORIZADO" | "NO ENCONTRADO O PENDIENTE", response: soap_xml}}
```

`environment`: `1` = test, `2` = production.

---

## 3. Module Map

```
lib/xml_builder.ex                                    CentrixCore.XmlBuilder
lib/xml_builder/dataset/factura.ex                    CentrixCore.Dataset.Factura (root schema)
lib/xml_builder/dataset/factura/info_tributaria.ex    CentrixCore.Dataset.Factura.InfoTributaria
lib/xml_builder/dataset/clave_acceso.ex               CentrixCore.Dataset.ClaveAcceso
lib/xml_builder/dataset/clave_acceso/digito_verificador.ex  ClaveAcceso.DigitoVerificador
lib/xml_builder/dataset/factura/info_factura.ex       CentrixCore.Dataset.Factura.InfoFactura
lib/xml_builder/dataset/factura/total_impuesto.ex     CentrixCore.Dataset.Factura.TotalImpuesto
lib/xml_builder/dataset/factura/pago.ex               CentrixCore.Dataset.Factura.Pago
lib/xml_builder/dataset/factura/detalle.ex            CentrixCore.Dataset.Factura.Detalle
lib/xml_builder/dataset/factura/det_adicional.ex      CentrixCore.Dataset.Factura.DetAdicional
lib/xml_builder/dataset/factura/impuesto.ex           CentrixCore.Dataset.Factura.Impuesto
lib/xml_builder/dataset/factura/campo_adicional.ex    CentrixCore.Dataset.Factura.CampoAdicional
```

---

## 4. Schema Field Reference

### 4.1 `Factura` (root) — `lib/xml_builder/dataset/factura.ex`

XML root element: `<factura id="comprobante" version="1.1.0">`

```
embeds_one  :info_tributaria  InfoTributaria   REQUIRED
embeds_one  :info_factura     InfoFactura      REQUIRED
embeds_many :detalles         Detalle          REQUIRED, min 1
embeds_many :info_adicional   CampoAdicional   REQUIRED (can be [])
```

---

### 4.2 `InfoTributaria` — `lib/xml_builder/dataset/factura/info_tributaria.ex`

| Field | Type | Required | Notes |
|---|---|---|---|
| `ambiente` | integer | ✅ | 1=test, 2=production |
| `tipo_emision` | integer | ✅ | 1=normal |
| `razon_social` | string | ✅ | Legal company name |
| `nombre_comercial` | string | ✅ | Trade name |
| `ruc` | string | ✅ | 13-digit tax ID |
| `cod_doc` | integer | ✅ | Always `1` for Factura |
| `estab` | integer | ✅ | Zero-padded to 3 digits in XML |
| `pto_emi` | integer | ✅ | Zero-padded to 3 digits in XML |
| `secuencial` | integer | ✅ | Zero-padded to 9 digits in XML |
| `dir_matriz` | string | ✅ | Main office address |
| `clave` | ClaveAcceso embed | ✅ | Used to compute `clave_acceso` |
| `clave_acceso` | string | — | **Auto-computed**, do NOT pass in params |

**Key behavior:** `changeset/2` calls `generate_clave_acceso/1` at the end, which runs `DigitoVerificador.generate(clave.changes)` and stores the result in `clave_acceso`.

XML output (note padding and order):
```xml
<infoTributaria>
  <ambiente>1</ambiente>
  <tipoEmision>1</tipoEmision>
  <razonSocial>...</razonSocial>
  <nombreComercial>...</nombreComercial>
  <ruc>1103671804001</ruc>
  <claveAcceso><!-- 49 digits, auto-computed --></claveAcceso>
  <codDoc>01</codDoc>
  <estab>001</estab>
  <ptoEmi>100</ptoEmi>
  <secuencial>000000433</secuencial>
  <dirMatriz>...</dirMatriz>
</infoTributaria>
```

---

### 4.3 `ClaveAcceso` — `lib/xml_builder/dataset/clave_acceso.ex`

All fields required. Used only as input for `DigitoVerificador`; not serialized to XML directly.

| Field | Type | Notes |
|---|---|---|
| `fecha_emision` | date | `"yyyy-mm-dd"` string in params |
| `tipo_comprobante` | integer | 1 for Factura |
| `ruc` | string | |
| `ambiente` | integer | |
| `estab` | integer | |
| `pto_emi` | integer | |
| `secuencial` | integer | |
| `codigo` | integer | Any random integer up to 8 digits |
| `tipo_emision` | integer | 1=normal |

**`clave_acceso` 49-char format:**
```
[ddmmyyyy:8][tipo_comprobante:2][ruc:13][ambiente:1][estab:3][pto_emi:3][secuencial:9][codigo:8][tipo_emision:1][digito_verificador:1]
```

**Módulo 11 algorithm** (`digito_verificador.ex`):
1. Reverse the 48-digit string, parse digits.
2. Multiply each by cycling weights `2,3,4,5,6,7,2,3,...`
3. Sum all, compute `rem(sum, 11)`, then `11 - rem`.
4. If result is `10` → use `1`; if `11` → use `0`.

---

### 4.4 `InfoFactura` — `lib/xml_builder/dataset/factura/info_factura.ex`

| Field | Type | Required | Notes |
|---|---|---|---|
| `fecha_emision` | date | ✅ | Formatted `dd/mm/yyyy` in XML |
| `dir_establecimiento` | string | ✅ | Branch address |
| `obligado_contabilidad` | string | ✅ | `"SI"` or `"NO"` |
| `contribuyente_especial` | string | — | Inserted in XML only when `obligado_contabilidad = "SI"` |
| `tipo_identificacion_comprador` | integer | ✅ | Zero-padded 2 digits in XML |
| `razon_social_comprador` | string | ✅ | Buyer's legal name |
| `identificacion_comprador` | string | ✅ | Buyer's tax/ID number |
| `direccion_comprador` | string | — | Optional |
| `total_sin_impuestos` | float | ✅ | 2 decimal places |
| `total_descuento` | float | ✅ | 2 decimal places |
| `propina` | float | ✅ | Tip; usually 0 |
| `importe_total` | float | ✅ | Grand total, 2 decimal places |
| `moneda` | string | ✅ | e.g., `"DOLAR"` |
| `total_con_impuestos` | `[TotalImpuesto]` | ✅ | Tax summary |
| `pagos` | `[Pago]` | ✅ | Payment methods |

**Conditional logic:** `add_contribuyente_especial/2` pattern-matches on `obligado_contabilidad: "SI"` and inserts `<contribuyenteEspecial>` at position 2 in the XML list.

---

### 4.5 `TotalImpuesto` — `lib/xml_builder/dataset/factura/total_impuesto.ex`

| Field | Type | Required | Notes |
|---|---|---|---|
| `codigo` | integer | ✅ | Tax type (2=IVA) |
| `codigo_porcentaje` | integer | ✅ | Rate code (0=0%, 2=12%, 4=15%, etc.) |
| `base_imponible` | float | ✅ | Taxable base |
| `valor` | float | ✅ | Tax amount |

XML: `<totalImpuesto><codigo/><codigoPorcentaje/><baseImponible/><valor/></totalImpuesto>`

---

### 4.6 `Pago` — `lib/xml_builder/dataset/factura/pago.ex`

| Field | Type | Required | Notes |
|---|---|---|---|
| `forma_pago` | integer | ✅ | Payment code; zero-padded 2 digits in XML |
| `total` | float | ✅ | 2 decimal places |
| `plazo` | integer | ✅ | Payment term number |
| `unidad_tiempo` | string | ✅ | e.g., `"Dias"`, `"Meses"` |

XML: `<pago><formaPago>20</formaPago><total>5.00</total><plazo>15</plazo><unidadTiempo>Dias</unidadTiempo></pago>`

---

### 4.7 `Detalle` — `lib/xml_builder/dataset/factura/detalle.ex`

| Field | Type | Required | Notes |
|---|---|---|---|
| `codigo_principal` | string | ✅ | Product/service code |
| `codigo_auxiliar` | string | — | **Optional** — XML element omitted entirely when `nil` |
| `descripcion` | string | ✅ | Description |
| `cantidad` | float | ✅ | **6 decimal places** in XML |
| `precio_unitario` | float | ✅ | **6 decimal places** in XML |
| `descuento` | float | ✅ | 2 decimal places |
| `precio_total_sin_impuesto` | float | ✅ | 2 decimal places |
| `detalles_adicionales` | `[DetAdicional]` | ✅ | Can be `[]` |
| `impuestos` | `[Impuesto]` | ✅ | Min 1 |

**`codigo_auxiliar` omission:** The field is built with `if(detalle.codigo_auxiliar, do: {:codigoAuxiliar, nil, detalle.codigo_auxiliar})` and filtered by `Enum.reject(&is_nil/1)`.

---

### 4.8 `DetAdicional` — `lib/xml_builder/dataset/factura/det_adicional.ex`

| Field | Type | Required |
|---|---|---|
| `nombre` | string | ✅ |
| `valor` | string | ✅ |

XML: `<detAdicional nombre="informacionAdicional" valor="desarrollo de software"/>` — self-closing, both values are XML **attributes**.

---

### 4.9 `Impuesto` (line-level) — `lib/xml_builder/dataset/factura/impuesto.ex`

| Field | Type | Required | Notes |
|---|---|---|---|
| `codigo` | integer | ✅ | Tax type |
| `codigo_porcentaje` | integer | ✅ | Rate code |
| `tarifa` | float | ✅ | Actual rate % (e.g., `0.0`, `15.0`) — **absent in TotalImpuesto** |
| `base_imponible` | float | ✅ | |
| `valor` | float | ✅ | |

> `tarifa` is the key field that distinguishes `Impuesto` (line-level) from `TotalImpuesto` (document-level).

---

### 4.10 `CampoAdicional` — `lib/xml_builder/dataset/factura/campo_adicional.ex`

| Field | Type | Required |
|---|---|---|
| `nombre` | string | ✅ |
| `valor` | string | ✅ |

XML: `<campoAdicional nombre="Email">user@example.com</campoAdicional>` — `nombre` is an XML **attribute**, `valor` is **text content**.

---

## 5. Minimal Input Params

```elixir
%{
  info_tributaria: %{
    ambiente: 1, tipo_emision: 1,
    razon_social: "COMPANY NAME", nombre_comercial: "TRADE NAME",
    ruc: "1103671804001", cod_doc: 1,
    estab: 1, pto_emi: 100, secuencial: 433,
    dir_matriz: "Main address...",
    clave: %{
      ambiente: 1, tipo_emision: 1, ruc: "1103671804001",
      estab: 1, pto_emi: 100, secuencial: 433,
      codigo: 12345678,          # any integer, up to 8 digits
      fecha_emision: "2025-05-15",
      tipo_comprobante: 1
    }
  },
  info_factura: %{
    fecha_emision: "2025-05-15",
    dir_establecimiento: "Branch address...",
    obligado_contabilidad: "NO",
    tipo_identificacion_comprador: 8,
    razon_social_comprador: "Buyer Name",
    identificacion_comprador: "465219513",
    total_sin_impuestos: 5.0, total_descuento: 0.0, propina: 0.0, importe_total: 5.0,
    moneda: "DOLAR",
    total_con_impuestos: [
      %{codigo: 2, codigo_porcentaje: 0, base_imponible: 5.0, valor: 0.0}
    ],
    pagos: [%{total: 5.0, forma_pago: 20, plazo: 15, unidad_tiempo: "Dias"}]
  },
  detalles: [
    %{
      codigo_principal: "PROD001",
      descripcion: "Product/Service Description",
      cantidad: 1.0, precio_unitario: 5.0, descuento: 0.0,
      precio_total_sin_impuesto: 5.0,
      detalles_adicionales: [],
      impuestos: [
        %{codigo: 2, codigo_porcentaje: 0, base_imponible: 5.0, valor: 0.0, tarifa: 0.0}
      ]
    }
  ],
  info_adicional: []   # or: [%{nombre: "Email", valor: "user@example.com"}]
}
```

---

## 6. Critical Conventions

| Rule | Detail |
|---|---|
| `cod_doc` | Always `1` for Factura |
| `tipo_comprobante` in `clave` | Must also be `1`; must match `cod_doc` |
| `clave_acceso` | Never pass in params; it is auto-computed |
| `obligado_contabilidad` | String `"SI"` or `"NO"`, not boolean |
| `contribuyente_especial` | XML element only appears when `obligado_contabilidad = "SI"` |
| `codigo_auxiliar` | Set to `nil` or omit to exclude the XML element entirely |
| `pagos` | Must have at least one entry |
| Date format in params | `"yyyy-mm-dd"` string; converted to `dd/mm/yyyy` in XML |
| Monetary precision | 2 decimal places for amounts, 6 for `cantidad` and `precio_unitario` |
| Numeric padding | `cod_doc`→2, `estab`/`pto_emi`→3, `secuencial`→9, `forma_pago`→2 digits |

---

## 7. Testing

- Unit tests: `test/xml_builder_test.exs`
- Fixtures: `test/fixtures/factura.xml`, `info_tributaria.xml`, `info_factura.xml`, `detalle.xml`, `impuesto.xml`, `pago.xml`, `total_impuesto.xml`, `campo_adicional.xml`, `det_adicional.xml`
- Sandbox (SRI test env): `TEST_P12_FILE_PASSWORD="pwd" mix run sandbox/test_invoice.exs`
