# Plan de Implementación: Guía de Remisión (cod_doc = 06)

## 1. Archivos a Crear / Modificar

- **Punto de Entrada:** `lib/xml_remission_guide_builder.ex`
- **Carpeta de Schemas:** `lib/xml_builder/dataset/guia_remision/`
- **Schemas Específicos:**
  - `guia_remision.ex` (Raíz)
  - `info_guia_remision.ex`
  - `destinatario.ex`
  - `detalle.ex` (Simplificado: sin precio ni impuestos)
- **Reutilizados:** 
  - `CentrixCore.Dataset.Factura.InfoTributaria` (Ajustando `cod_doc: 6`)
  - `CentrixCore.Dataset.Factura.CampoAdicional`
- **Tests:**
  - `test/xml_remission_guide_builder_test.exs`
  - `test/fixtures/guia_remision/`
  - `sandbox/remission_guide_sandbox.ex` y `sandbox/test_remission_guide.exs`

## 2. Definición de Ecto Schemas (Novedades)

### `CentrixCore.Dataset.GuiaRemision.InfoGuiaRemision`
Define los datos del transportista y del traslado.
| Campo | XML Tag | Requerido |
|---|---|---|
| `dir_establecimiento` | `<dirEstablecimiento>` | No |
| `dir_partida` | `<dirPartida>` | Sí |
| `razon_social_transportista` | `<razonSocialTransportista>` | Sí |
| `tipo_identificacion_transportista`| `<tipoIdentificacionTransportista>` | Sí |
| `ruc_transportista` | `<rucTransportista>` | Sí |
| `rise` | `<rise>` | No |
| `obligado_contabilidad` | `<obligadoContabilidad>` | No (SI/NO)|
| `contribuyente_especial` | `<contribuyenteEspecial>` | No |
| `fecha_ini_transporte` | `<fechaIniTransporte>` | Sí |
| `fecha_fin_transporte` | `<fechaFinTransporte>` | Sí |
| `placa` | `<placa>` | Sí |

### `CentrixCore.Dataset.GuiaRemision.Destinatario`
Una guía puede tener múltiples destinatarios. 
Campos principales: `identificacion_destinatario`, `razon_social_destinatario`, `dir_destinatario`, `motivo_traslado`.
Campos opcionales para aduanas / sustento: `doc_aduanero_unico`, `cod_estab_destino`, `ruta`, `cod_doc_sustento`, `num_doc_sustento`, `num_aut_doc_sustento`, `fecha_emision_doc_sustento`.
**Relación:** `detalles` (EmbedsMany). ¡Ojo! Los detalles van dentro de cada destinatario.

### `CentrixCore.Dataset.GuiaRemision.Detalle`
Detalle de los bienes transportados (no monetario):
- `codigo_interno` (Opcional)
- `codigo_adicional` (Opcional)
- `descripcion` (Sí)
- `cantidad` (Sí)
- `detalles_adicionales` (EmbedsMany Opcional)

## 3. Serialización XML (`to_doc/to_xml`)

- El nodo principal debe ser `<guiaRemision id="comprobante" version="1.0.0">`.
- Estructura y orden:
  1. `<infoTributaria>`
  2. `<infoGuiaRemision>`
  3. `<destinatarios>` (Que agrupa a múltiples `<destinatario>`)
  4. `<infoAdicional>` (Opcional)
- A diferencia de la factura, no hay bloque de impuestos ni de pagos a nivel de raíz ni de detalle. El documento certifica el transporte, no la venta.

## 4. Plan de Pruebas

1. **Test Estructural de Destinatarios:** Verificar que se generen correctamente los XML con uno y con múltiples `<destinatario>`, asegurando que los detalles caigan correctamente bajo cada destinatario.
2. **Validación de Fechas:** Las guías manejan `fecha_ini_transporte` y `fecha_fin_transporte`. Asegurar que el formateo `dd/mm/aaaa` sea aplicado correctamente.
3. **Módulo 11:** `tipo_comprobante: 6`.
