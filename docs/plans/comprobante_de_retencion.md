# Plan de Implementación: Comprobante de Retención v2.0.0 (cod_doc = 07)

## 1. Archivos a Crear / Modificar

- **Punto de Entrada:** `lib/xml_retention_builder.ex`
- **Carpeta de Schemas:** `lib/xml_builder/dataset/comprobante_retencion/`
- **Schemas Específicos:**
  - `comprobante_retencion.ex` (Raíz)
  - `info_comp_retencion.ex`
  - `doc_sustento.ex` (Bloque de documentos asociados)
  - `impuesto_doc_sustento.ex`
  - `retencion.ex`
  - `dividendo.ex`
  - `compra_caj_banano.ex`
  - `reembolso_detalle.ex` y `detalle_impuesto.ex` (Para casos de reembolso)
  - `pago.ex` (Para mapear `<formapago>`)
- **Reutilizados:** 
  - `CentrixCore.Dataset.Factura.InfoTributaria` (Ajustando `cod_doc: 7`)
  - `CentrixCore.Dataset.Factura.CampoAdicional`
- **Tests:**
  - `test/xml_retention_builder_test.exs`
  - `test/fixtures/comprobante_retencion/`
  - `sandbox/retention_sandbox.ex` y `sandbox/test_retention.exs`

## 2. Definición de Ecto Schemas (Resumen Estructural)

La estructura de Retenciones es profundamente anidada. La jerarquía es:
`ComprobanteRetencion` -> `DocsSustento` -> `DocSustento`.

### `InfoCompRetencion`
Información del sujeto retenido:
- `fecha_emision`
- `tipo_identificacion_sujeto_retenido`, `identificacion_sujeto_retenido`, `razon_social_sujeto_retenido`
- `periodo_fiscal` (Formato mm/aaaa)
- `parte_rel` (SI/NO)
- Opcionales: `dir_establecimiento`, `contribuyente_especial`, `obligado_contabilidad`, `tipo_sujeto_retenido` (obligatorio si la identificación es de exterior).

### `DocSustento`
El corazón del documento. Contiene los detalles de lo que se está reteniendo:
- Campos básicos: `cod_sustento`, `cod_doc_sustento`, `num_doc_sustento` (Opcional), `fecha_emision_doc_sustento`.
- Identificadores fiscales / ATS: `pago_loc_ext`, `tipo_regi`, `pais_efec_pago`, `aplic_conv_dob_trib`, etc.
- Totales: `total_sin_impuestos`, `importe_total`.
- **Relaciones (EmbedsMany):**
  - `impuestos_doc_sustento` (`ImpuestoDocSustento`)
  - `retenciones` (`Retencion`)
  - `reembolsos` (`ReembolsoDetalle` - opcional)
  - `pagos` (`Pago`)

### `Retencion`
Define cuánto se retiene:
- `codigo` (Ej. 1 para Renta, 2 para IVA)
- `codigo_retencion`
- `base_imponible`
- `porcentaje_retener`
- `valor_retenido`
- Embeds opcionales: `dividendos` y `compra_caj_banano`.

### `Pago` (Particularidad v2.0.0)
La Ficha Técnica indica que la etiqueta XML para la forma de pago dentro de `<pagos>` es `<formapago>` (con la 'p' minúscula), a diferencia de Facturas que usa `formaPago`. Se debe implementar un schema específico de Pago para Retención que respete este tag literal, además del `<total>`.

## 3. Serialización XML (`to_doc/to_xml`)

- El nodo principal debe ser `<comprobanteRetencion id="comprobante" version="2.0.0">`.
- Las fechas varían: `fecha_emision` es `dd/mm/aaaa`, pero `periodo_fiscal` es `mm/aaaa`. Se debe tener cuidado con el formateo de estas fechas al serializar.
- Orden de bloques raíz:
  1. `<infoTributaria>`
  2. `<infoCompRetencion>`
  3. `<docsSustento>` (Que envuelve múltiples `<docSustento>`)
  4. `<infoAdicional>` (Opcional)

## 4. Plan de Pruebas

1. **Test Unitario:** Un test exhaustivo que valide un comprobante con dividendos, banano y pagos al exterior para cubrir todos los campos condicionales.
2. **Formato Periodo Fiscal:** Testear específicamente que el campo `periodo_fiscal` se renderiza correctamente como `mm/aaaa`.
3. **Módulo 11:** `tipo_comprobante: 7`.
