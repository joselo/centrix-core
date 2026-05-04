# Plan de Implementación: Nota de Débito (cod_doc = 05)

## 1. Archivos a Crear / Modificar

- **Punto de Entrada:** `lib/xml_debit_note_builder.ex`
- **Carpeta de Schemas:** `lib/xml_builder/dataset/nota_debito/`
- **Schemas Específicos:**
  - `nota_debito.ex` (Raíz)
  - `info_nota_debito.ex`
  - `impuesto.ex` (Similar al de Factura pero dentro de `infoNotaDebito`)
  - `pago.ex` (Comparte estructura con Factura)
  - `motivo.ex`
- **Reutilizados:** 
  - `BillingCore.Dataset.Factura.InfoTributaria` (Ajustando `cod_doc: 5`)
  - `BillingCore.Dataset.Factura.CampoAdicional`
- **Tests:**
  - `test/xml_debit_note_builder_test.exs`
  - `test/fixtures/nota_debito/` (nota_debito.xml, etc.)
  - `sandbox/debit_note_sandbox.ex` y `sandbox/test_debit_note.exs`

## 2. Definición de Ecto Schemas

### `BillingCore.Dataset.NotaDebito.InfoNotaDebito`
| Campo | XML Tag | Tipo | Requerido |
|---|---|---|---|
| `fecha_emision` | `<fechaEmision>` | Date | Sí |
| `dir_establecimiento` | `<dirEstablecimiento>` | String | No |
| `tipo_identificacion_comprador` | `<tipoIdentificacionComprador>`| String | Sí |
| `razon_social_comprador` | `<razonSocialComprador>` | String | Sí |
| `identificacion_comprador` | `<identificacionComprador>` | String | Sí |
| `contribuyente_especial` | `<contribuyenteEspecial>` | String | No |
| `obligado_contabilidad` | `<obligadoContabilidad>` | String (SI/NO)| No |
| `cod_doc_modificado` | `<codDocModificado>` | String | Sí |
| `num_doc_modificado` | `<numDocModificado>` | String | Sí |
| `fecha_emision_doc_sustento`| `<fechaEmisionDocSustento>` | Date | Sí |
| `total_sin_impuestos` | `<totalSinImpuestos>` | Float | Sí |
| `impuestos` | `<impuestos>` -> `<impuesto>` | EmbedsMany | Sí |
| `valor_total` | `<valorTotal>` | Float | Sí |
| `pagos` | `<pagos>` -> `<pago>` | EmbedsMany | Sí |

### `BillingCore.Dataset.NotaDebito.Motivo`
| Campo | XML Tag | Tipo | Requerido |
|---|---|---|---|
| `razon` | `<razon>` | String (Max 300) | Sí |
| `valor` | `<valor>` | Float | Sí |

## 3. Serialización XML (`to_doc/to_xml`)

- El nodo principal debe ser `<notaDebito version="1.0.0" id="comprobante">`.
- El campo `obligadoContabilidad` debe omitirse si es `nil` (Igual que en Nota de Crédito).
- Precisión numérica: 2 decimales para `valor` y `valorTotal`.
- El orden exacto de los bloques hijos en la raíz:
  1. `<infoTributaria>`
  2. `<infoNotaDebito>`
  3. `<motivos>`
  4. `<infoAdicional>` (Opcional)

## 4. Plan de Pruebas

1. **Test Unitario Estructural:** Validar que al enviar parámetros, el XML generado coincide bit a bit (ignorando espacios/saltos de línea) con el fixture obtenido de la Ficha Técnica.
2. **Validación de Clave:** Verificar que se invoque correctamente `DigitoVerificador` pasando `tipo_comprobante: 5`.
3. **Sandbox E2E:** Escribir un script que levante el XML, lo firme con el certificado de prueba, lo envíe a recepción SRI (Test) y confirme que el estado de autorización sea `AUTORIZADO`.
