# Nota de Crédito (Credit Note) — Implementation Reference

> **Intended audience:** AI agents and developers maintaining or extending the credit note implementation in `CentrixCore`. This document is a code-level reference for the Nota de Crédito (`cod_doc = 04`) document type.
>
> **Relationship to Factura:** The Nota de Crédito shares ~80% of its structure with the Factura. Read [facturas.md](./facturas.md) first. This document focuses on what is **different**.

---

## 1. Overview

A **Nota de Crédito** (credit note, `cod_doc = 04`) corrects or reverses a previously issued Factura (or other document). It must reference the original document via `cod_doc_modificado` and `num_doc_modificado`.

Key differences from Factura:
- Uses `info_nota_credito` instead of `info_factura`
- Has **no `pagos` (payments)** block
- Has a `motivo` (reason) field
- References the original document (`cod_doc_modificado`, `num_doc_modificado`, `fecha_emision_doc_sustento`)
- Has a `valor_modificacion` (corrected amount) instead of `importe_total`
- `Detalle` uses `codigo_interno`/`codigo_adicional` instead of `codigo_principal`/`codigo_auxiliar`
- `InfoTributaria` supports an optional `agente_retencion` field

---

## 2. Public Entry Points

```elixir
# Build XML
CentrixCore.XmlCreditNoteBuilder.build_credit_note(params)
# => {:ok, [xml: xml_string, clave_acceso: "49-digit-key"]}
# => {:error, %Ecto.Changeset{}}

# Sign — identical to Factura
CentrixCore.Signing.sign(xml_string, p12_path, p12_password)
# => {:ok, signed_xml_string}

# Send to SRI — identical to Factura
CentrixCore.SriClient.send_document(signed_xml, environment)
# => {:ok, %{status: "RECIBIDA" | "DEVUELTA", response: soap_xml}}

# Poll authorization — identical to Factura
CentrixCore.SriClient.is_authorized(clave_acceso, environment)
# => {:ok, %{status: "AUTORIZADO" | "NO AUTORIZADO" | "NO ENCONTRADO O PENDIENTE", response: soap_xml}}
```

`environment`: `1` = test, `2` = production.

---

## 3. Module Map

```
lib/xml_credit_note_builder.ex                          CentrixCore.XmlCreditNoteBuilder
lib/xml_builder/dataset/nota_credito.ex                 CentrixCore.Dataset.NotaCredito (root)
lib/xml_builder/dataset/nota_credito/info_tributaria.ex CentrixCore.Dataset.NotaCredito.InfoTributaria
lib/xml_builder/dataset/clave_acceso.ex                 CentrixCore.Dataset.ClaveAcceso        (SHARED)
lib/xml_builder/dataset/clave_acceso/digito_verificador.ex  ClaveAcceso.DigitoVerificador      (SHARED)
lib/xml_builder/dataset/nota_credito/info_nota_credito.ex   CentrixCore.Dataset.NotaCredito.InfoNotaCredito
lib/xml_builder/dataset/nota_credito/total_impuesto.ex  CentrixCore.Dataset.NotaCredito.TotalImpuesto
lib/xml_builder/dataset/nota_credito/detalle.ex         CentrixCore.Dataset.NotaCredito.Detalle
lib/xml_builder/dataset/nota_credito/det_adicional.ex   CentrixCore.Dataset.NotaCredito.DetAdicional
lib/xml_builder/dataset/nota_credito/impuesto.ex        CentrixCore.Dataset.NotaCredito.Impuesto
lib/xml_builder/dataset/nota_credito/campo_adicional.ex CentrixCore.Dataset.NotaCredito.CampoAdicional
```

> `ClaveAcceso` and `DigitoVerificador` are **shared** with the Factura implementation under `lib/xml_builder/dataset/`.

---

## 4. Schema Field Reference

### 4.1 `NotaCredito` (root) — `lib/xml_builder/dataset/nota_credito.ex`

XML root element: `<notaCredito id="comprobante" version="1.1.0">`

```
embeds_one  :info_tributaria   InfoTributaria    REQUIRED
embeds_one  :info_nota_credito InfoNotaCredito   REQUIRED
embeds_many :detalles          Detalle           REQUIRED, min 1
embeds_many :info_adicional    CampoAdicional    REQUIRED (can be [])
```

---

### 4.2 `InfoTributaria` — `lib/xml_builder/dataset/nota_credito/info_tributaria.ex`

**Nearly identical to Factura's `InfoTributaria`, with one addition:**

| Field | Type | Required | Notes |
|---|---|---|---|
| `ambiente` | integer | ✅ | 1=test, 2=production |
| `tipo_emision` | integer | ✅ | 1=normal |
| `razon_social` | string | ✅ | |
| `nombre_comercial` | string | ✅ | |
| `ruc` | string | ✅ | 13 digits |
| `cod_doc` | integer | ✅ | Always `4` for Nota de Crédito |
| `estab` | integer | ✅ | Zero-padded 3 digits in XML |
| `pto_emi` | integer | ✅ | Zero-padded 3 digits in XML |
| `secuencial` | integer | ✅ | Zero-padded 9 digits in XML |
| `dir_matriz` | string | ✅ | |
| `agente_retencion` | integer | — | **Optional, unique to NotaCredito**. Zero-padded 8 digits. Inserted at index 2 when present. |
| `clave` | ClaveAcceso embed | ✅ | Same as Factura |
| `clave_acceso` | string | — | Auto-computed, do NOT pass |

**`agente_retencion` conditional logic** (`add_agente_retencion/2`):
- Pattern-matches `%{agente_retencion: nil}` → returns `doc` unchanged.
- When present: converts to string, pads to 8 digits, inserts `<agente_retencion>` at index 2.

XML output:
```xml
<infoTributaria>
  <ambiente>1</ambiente>
  <tipoEmision>1</tipoEmision>
  <agente_retencion>00000001</agente_retencion>  <!-- only if present, at index 2 -->
  <razonSocial>...</razonSocial>
  <nombreComercial>...</nombreComercial>
  <ruc>1103671804001</ruc>
  <claveAcceso><!-- 49 digits --></claveAcceso>
  <codDoc>04</codDoc>
  <estab>001</estab>
  <ptoEmi>001</ptoEmi>
  <secuencial>000000001</secuencial>
  <dirMatriz>...</dirMatriz>
</infoTributaria>
```

---

### 4.3 `ClaveAcceso` (shared)

Same module and algorithm as Factura. The only difference is:
- `tipo_comprobante` must be `4` (not `1`)
- `cod_doc` in `info_tributaria` must also be `4`

See [facturas.md § 4.3](./facturas.md#43-claveacceso----libxml_builderdatasetclave_accesox) for the full Módulo 11 algorithm.

---

### 4.4 `InfoNotaCredito` — `lib/xml_builder/dataset/nota_credito/info_nota_credito.ex`

This replaces `InfoFactura`. It has **no `pagos`** and adds fields for the referenced document.

| Field | Type | Required | Notes |
|---|---|---|---|
| `fecha_emision` | date | ✅ | Formatted `dd/mm/yyyy` in XML |
| `dir_establecimiento` | string | ✅ | Branch address |
| `tipo_identificacion_comprador` | integer | ✅ | Zero-padded 2 digits in XML |
| `razon_social_comprador` | string | ✅ | |
| `identificacion_comprador` | string | ✅ | |
| `obligado_contabilidad` | string | — | `"SI"` or `"NO"`. Used for conditional logic only |
| `contribuyente_especial` | string | — | Inserted in XML when `obligado_contabilidad = "SI"` and this is present |
| `rise` | string | — | Optional. Inserted at index 2 when present |
| `cod_doc_modificado` | string | ✅ | Code of original doc (e.g., `"01"` for Factura) |
| `num_doc_modificado` | string | ✅ | Number of original doc (e.g., `"001-100-000000433"`) |
| `fecha_emision_doc_sustento` | date | ✅ | Emission date of original doc, `dd/mm/yyyy` in XML |
| `total_sin_impuestos` | float | ✅ | 2 decimal places |
| `valor_modificacion` | float | ✅ | Amount being credited. 2 decimal places |
| `moneda` | string | ✅ | e.g., `"DOLAR"` |
| `motivo` | string | ✅ | Reason for the credit note |
| `total_con_impuestos` | `[TotalImpuesto]` | ✅ | Tax summary |

**Conditional logic (two rules):**

1. **`contribuyente_especial`** (`add_contribuyente_especial/2`):
   - When `obligado_contabilidad = "SI"` **and** `contribuyente_especial` is present → inserts `<contribuyenteEspecial>` at index 2.
   - When `obligado_contabilidad = "SI"` **and** `contribuyente_especial` is `nil` → inserts `<obligadoContabilidad>SI</obligadoContabilidad>` at index 2 instead.
   - Otherwise → no insertion.

2. **`rise`** (`add_rise/2`):
   - When `nil` → no change.
   - When present → inserts `<rise>` at index 2.

> Both `contribuyente_especial` and `rise` insert at position 2. If both are present, order depends on which runs last (`add_rise` runs after `add_contribuyente_especial`).

XML output:
```xml
<infoNotaCredito>
  <fechaEmision>15/05/2025</fechaEmision>
  <dirEstablecimiento>...</dirEstablecimiento>
  <!-- contribuyenteEspecial or obligadoContabilidad inserted here if applicable -->
  <!-- rise inserted here if applicable -->
  <tipoIdentificacionComprador>08</tipoIdentificacionComprador>
  <razonSocialComprador>Novaux Inc.</razonSocialComprador>
  <identificacionComprador>465219513</identificacionComprador>
  <codDocModificado>01</codDocModificado>
  <numDocModificado>001-100-000000433</numDocModificado>
  <fechaEmisionDocSustento>15/05/2025</fechaEmisionDocSustento>
  <totalSinImpuestos>5.00</totalSinImpuestos>
  <valorModificacion>5.00</valorModificacion>
  <moneda>DOLAR</moneda>
  <totalConImpuestos>
    <totalImpuesto>...</totalImpuesto>
  </totalConImpuestos>
  <motivo>NOTA DE CREDITO POR DEVOLUCION DE PRODUCTOS</motivo>
</infoNotaCredito>
```

---

### 4.5 `TotalImpuesto` — `lib/xml_builder/dataset/nota_credito/total_impuesto.ex`

Identical structure to Factura's `TotalImpuesto`:

| Field | Type | Required |
|---|---|---|
| `codigo` | integer | ✅ |
| `codigo_porcentaje` | integer | ✅ |
| `base_imponible` | float | ✅ |
| `valor` | float | ✅ |

XML: `<totalImpuesto><codigo/><codigoPorcentaje/><baseImponible/><valor/></totalImpuesto>`

---

### 4.6 `Detalle` — `lib/xml_builder/dataset/nota_credito/detalle.ex`

**Different field names from Factura's `Detalle`:**

| Field (NotaCredito) | Field (Factura) | Type | Required | Notes |
|---|---|---|---|---|
| `codigo_interno` | `codigo_principal` | string | ✅ | Required, always in XML |
| `codigo_adicional` | `codigo_auxiliar` | string | ✅ | Required (unlike Factura where it's optional) |
| `descripcion` | same | string | ✅ | |
| `cantidad` | same | float | ✅ | 6 decimal places in XML |
| `precio_unitario` | same | float | ✅ | 6 decimal places in XML |
| `descuento` | same | float | ✅ | 2 decimal places |
| `precio_total_sin_impuesto` | same | float | ✅ | 2 decimal places |
| `detalles_adicionales` | same | `[DetAdicional]` | ✅ | Can be `[]` |
| `impuestos` | same | `[Impuesto]` | ✅ | Min 1 |

> **Critical difference:** `codigo_adicional` is **required** in `NotaCredito.Detalle` (listed in `validate_required`), whereas `codigo_auxiliar` is **optional** in `Factura.Detalle`. There is no `nil`-filtering logic here.

XML output:
```xml
<detalle>
  <codigoInterno>831410399</codigoInterno>
  <codigoAdicional>2</codigoAdicional>
  <descripcion>SERVICIOS PROFESIONALES</descripcion>
  <cantidad>1.000000</cantidad>
  <precioUnitario>5.000000</precioUnitario>
  <descuento>0.00</descuento>
  <precioTotalSinImpuesto>5.00</precioTotalSinImpuesto>
  <detallesAdicionales>...</detallesAdicionales>
  <impuestos>...</impuestos>
</detalle>
```

---

### 4.7 `DetAdicional` — `lib/xml_builder/dataset/nota_credito/det_adicional.ex`

Identical to Factura's `DetAdicional`. Fields: `nombre`, `valor` (both required).

XML: `<detAdicional nombre="informacionAdicional" valor="desarrollo de software"/>` (self-closing, both as XML attributes).

---

### 4.8 `Impuesto` — `lib/xml_builder/dataset/nota_credito/impuesto.ex`

Identical to Factura's `Impuesto`. Fields: `codigo`, `codigo_porcentaje`, `tarifa`, `base_imponible`, `valor` (all required).

XML: `<impuesto><codigo/><codigoPorcentaje/><tarifa/><baseImponible/><valor/></impuesto>`

---

### 4.9 `CampoAdicional` — `lib/xml_builder/dataset/nota_credito/campo_adicional.ex`

Identical to Factura's `CampoAdicional`. Fields: `nombre`, `valor` (both required).

XML: `<campoAdicional nombre="Email">user@example.com</campoAdicional>`

---

## 5. Complete XML Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<notaCredito id="comprobante" version="1.1.0">
  <infoTributaria>
    <ambiente>1</ambiente>
    <tipoEmision>1</tipoEmision>
    <razonSocial>CARRION JUMBO JOSE AUGUSTO</razonSocial>
    <nombreComercial>INITMAIN</nombreComercial>
    <ruc>1103671804001</ruc>
    <claveAcceso><!-- 49 digits --></claveAcceso>
    <codDoc>04</codDoc>
    <estab>001</estab>
    <ptoEmi>001</ptoEmi>
    <secuencial>000000001</secuencial>
    <dirMatriz>Ciudadela: DAMMER II...</dirMatriz>
  </infoTributaria>
  <infoNotaCredito>
    <fechaEmision>15/05/2025</fechaEmision>
    <dirEstablecimiento>Ciudadela: DAMMER II...</dirEstablecimiento>
    <tipoIdentificacionComprador>08</tipoIdentificacionComprador>
    <razonSocialComprador>Novaux Inc.</razonSocialComprador>
    <identificacionComprador>465219513</identificacionComprador>
    <codDocModificado>01</codDocModificado>
    <numDocModificado>001-100-000000433</numDocModificado>
    <fechaEmisionDocSustento>15/05/2025</fechaEmisionDocSustento>
    <totalSinImpuestos>5.00</totalSinImpuestos>
    <valorModificacion>5.00</valorModificacion>
    <moneda>DOLAR</moneda>
    <totalConImpuestos>
      <totalImpuesto>
        <codigo>2</codigo>
        <codigoPorcentaje>0</codigoPorcentaje>
        <baseImponible>5.00</baseImponible>
        <valor>0.00</valor>
      </totalImpuesto>
    </totalConImpuestos>
    <motivo>NOTA DE CREDITO POR DEVOLUCION DE PRODUCTOS</motivo>
  </infoNotaCredito>
  <detalles>
    <detalle>
      <codigoInterno>831410399</codigoInterno>
      <codigoAdicional>2</codigoAdicional>
      <descripcion>SERVICIOS PROFESIONALES NOVAUX INC.</descripcion>
      <cantidad>1.000000</cantidad>
      <precioUnitario>5.000000</precioUnitario>
      <descuento>0.00</descuento>
      <precioTotalSinImpuesto>5.00</precioTotalSinImpuesto>
      <detallesAdicionales>
        <detAdicional nombre="informacionAdicional" valor="desarrollo de software"/>
      </detallesAdicionales>
      <impuestos>
        <impuesto>
          <codigo>2</codigo>
          <codigoPorcentaje>0</codigoPorcentaje>
          <tarifa>0.00</tarifa>
          <baseImponible>5.00</baseImponible>
          <valor>0.00</valor>
        </impuesto>
      </impuestos>
    </detalle>
  </detalles>
  <infoAdicional>
    <campoAdicional nombre="Direccion">East 109 St - 6J Manhattan NY</campoAdicional>
    <campoAdicional nombre="Email">javier@example.com</campoAdicional>
  </infoAdicional>
</notaCredito>
```

---

## 6. Minimal Input Params

```elixir
%{
  info_tributaria: %{
    ambiente: 1, tipo_emision: 1,
    razon_social: "COMPANY NAME", nombre_comercial: "TRADE NAME",
    ruc: "1103671804001",
    cod_doc: 4,           # 4 = Nota de Crédito
    estab: 1, pto_emi: 1, secuencial: 1,
    dir_matriz: "Main address...",
    clave: %{
      ambiente: 1, tipo_emision: 1, ruc: "1103671804001",
      estab: 1, pto_emi: 1, secuencial: 1,
      codigo: 12345678,
      fecha_emision: "2025-05-15",
      tipo_comprobante: 4   # 4 = Nota de Crédito
    }
  },
  info_nota_credito: %{
    fecha_emision: "2025-05-15",
    dir_establecimiento: "Branch address...",
    tipo_identificacion_comprador: 8,
    razon_social_comprador: "Buyer Name",
    identificacion_comprador: "465219513",
    cod_doc_modificado: "01",                    # "01" = Factura
    num_doc_modificado: "001-100-000000433",      # estab-pto_emi-secuencial of original
    fecha_emision_doc_sustento: "2025-05-15",
    total_sin_impuestos: 5.0,
    valor_modificacion: 5.0,
    moneda: "DOLAR",
    motivo: "CREDIT NOTE REASON",
    total_con_impuestos: [
      %{codigo: 2, codigo_porcentaje: 0, base_imponible: 5.0, valor: 0.0}
    ]
    # No pagos!
  },
  detalles: [
    %{
      codigo_interno: "PROD001",       # required (vs codigo_principal in Factura)
      codigo_adicional: "AUX001",      # required (vs optional codigo_auxiliar in Factura)
      descripcion: "Product/Service",
      cantidad: 1.0, precio_unitario: 5.0, descuento: 0.0,
      precio_total_sin_impuesto: 5.0,
      detalles_adicionales: [],
      impuestos: [
        %{codigo: 2, codigo_porcentaje: 0, base_imponible: 5.0, valor: 0.0, tarifa: 0.0}
      ]
    }
  ],
  info_adicional: []
}
```

---

## 7. Differences from Factura — Summary Table

| Aspect | Factura | Nota de Crédito |
|---|---|---|
| XML root element | `<factura>` | `<notaCredito>` |
| `cod_doc` | `1` | `4` |
| `tipo_comprobante` in `clave` | `1` | `4` |
| Transaction info block | `info_factura` / `InfoFactura` | `info_nota_credito` / `InfoNotaCredito` |
| Has `pagos` | ✅ Yes | ❌ No |
| Has `motivo` | ❌ No | ✅ Yes (required) |
| Has `valor_modificacion` | ❌ No | ✅ Yes (required) |
| Has `cod_doc_modificado` | ❌ No | ✅ Yes (required) |
| Has `num_doc_modificado` | ❌ No | ✅ Yes (required) |
| Has `fecha_emision_doc_sustento` | ❌ No | ✅ Yes (required) |
| Has `rise` | ❌ No | ✅ Optional |
| `InfoTributaria.agente_retencion` | ❌ No | ✅ Optional |
| Detalle code field 1 | `codigo_principal` (required) | `codigo_interno` (required) |
| Detalle code field 2 | `codigo_auxiliar` (optional, nil omits XML) | `codigo_adicional` (**required**) |
| Module namespace | `CentrixCore.Dataset.Factura.*` | `CentrixCore.Dataset.NotaCredito.*` |
| Entry point | `CentrixCore.XmlBuilder.build_invoice/1` | `CentrixCore.XmlCreditNoteBuilder.build_credit_note/1` |

---

## 8. Guidance for Implementing Future Document Types

The Nota de Crédito pattern is the recommended template for adding new SRI document types (e.g., Nota de Débito, Retención). Follow this checklist:

1. **Create a dataset directory:** `lib/xml_builder/dataset/<doc_type>/`
2. **Reuse `ClaveAcceso` and `DigitoVerificador`** — these are shared across all document types.
3. **Copy `InfoTributaria`** from `nota_credito/info_tributaria.ex` and adjust:
   - `cod_doc` value in the schema docs/comments
   - Any new optional fields (like `agente_retencion`)
4. **Create the transaction info block** (e.g., `InfoNotaDebito`) modelling it after `InfoNotaCredito`:
   - Replace document-specific fields
   - Add reference fields if correcting another document
5. **Create `Detalle`** — copy from `nota_credito/detalle.ex`. Adjust field names as required by SRI spec.
6. **Copy unchanged modules:** `TotalImpuesto`, `Impuesto`, `DetAdicional`, `CampoAdicional` are identical across all document types — just change the module namespace.
7. **Create root schema** (e.g., `nota_debito.ex`) following the `nota_credito.ex` pattern:
   - Update XML root element name
   - Update embed names
8. **Create the public entry point** (e.g., `xml_debit_note_builder.ex`) following `xml_credit_note_builder.ex`.
9. **Add sandbox test** in `sandbox/` and unit tests in `test/`.

---

## 9. Testing

- Unit tests: `test/xml_credit_note_builder_test.exs`
- Fixtures: `test/fixtures/nota_credito/` directory
- Sandbox (SRI test env): `TEST_P12_FILE_PASSWORD="pwd" mix run sandbox/test_credit_note.exs`
