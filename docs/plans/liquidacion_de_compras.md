# Plan de Implementación: Liquidación de Compra (cod_doc = 03)

## 1. Archivos a Crear / Modificar

- **Punto de Entrada:** `lib/xml_purchase_settlement_builder.ex`
- **Carpeta de Schemas:** `lib/xml_builder/dataset/liquidacion_compra/`
- **Schemas Específicos:**
  - `liquidacion_compra.ex` (Raíz)
  - `info_liquidacion_compra.ex`
  - `detalle.ex` (Lleva `unidadMedida` como extra vs Factura)
  - `total_impuesto.ex` (Lleva `descuentoAdicional` como extra vs Factura)
  - `reembolso_detalle.ex` (Bloque nuevo opcional)
  - `maquina_fiscal.ex` (Bloque nuevo opcional)
- **Reutilizados:** 
  - `BillingCore.Dataset.Factura.InfoTributaria` (Ajustando `cod_doc: 3`)
  - `BillingCore.Dataset.Factura.Impuesto`
  - `BillingCore.Dataset.Factura.Pago`
  - `BillingCore.Dataset.Factura.CampoAdicional`
- **Tests:**
  - `test/xml_purchase_settlement_builder_test.exs`
  - `test/fixtures/liquidacion_compra/`
  - `sandbox/purchase_settlement_sandbox.ex` y `sandbox/test_purchase_settlement.exs`

## 2. Definición de Ecto Schemas (Novedades vs Factura)

### `BillingCore.Dataset.LiquidacionCompra.InfoLiquidacionCompra`
Se invierten lógicamente los roles (el emisor del XML es el comprador, y el nodo describe al "proveedor").

| Campo (Elixir) | XML Tag | Requerido | Notas |
|---|---|---|---|
| `fecha_emision` | `<fechaEmision>` | Sí | |
| `dir_establecimiento` | `<dirEstablecimiento>` | No | |
| `tipo_identificacion_proveedor` | `<tipoIdentificacionProveedor>` | No | Conforme tabla 6 |
| `razon_social_proveedor` | `<razonSocialProveedor>` | Sí | |
| `identificacion_proveedor` | `<identificacionProveedor>` | Sí | |
| `direccion_proveedor` | `<direccionProveedor>` | No | |
| `total_sin_impuestos` | `<totalSinImpuestos>` | Sí | Sumatoria bases imponibles |
| `total_descuento` | `<totalDescuento>` | No | |
| `cod_doc_reembolso` | `<codDocReembolso>` | Cond. | Obligatorio si es 41 |
| `total_comprobantes_reembolso` | `<totalComprobantesReembolso>` | Cond. | |
| `total_base_imponible_reembolso`| `<totalBaseImponibleReembolso>`| Cond. | |
| `total_impuesto_reembolso` | `<totalImpuestoReembolso>` | Cond. | |
| `total_con_impuestos` | `<totalConImpuestos>` -> `<totalImpuesto>` | Sí | Usar el nuevo TotalImpuesto |
| `importe_total` | `<importeTotal>` | Sí | |
| `moneda` | `<moneda>` | Sí | "DOLAR" |
| `pagos` | `<pagos>` -> `<pago>` | Sí | |

### `BillingCore.Dataset.LiquidacionCompra.TotalImpuesto`
Similar a Factura, pero agrega `<descuentoAdicional>`:
- `codigo`
- `codigo_porcentaje`
- `descuento_adicional` (Opcional, numérico max 14)
- `base_imponible`
- `tarifa`
- `valor`

### `BillingCore.Dataset.LiquidacionCompra.Detalle`
Agrega un nuevo campo `<unidadMedida>` después de la descripción:
- `codigo_principal`
- `codigo_auxiliar` (Opcional)
- `descripcion`
- `unidad_medida` (Opcional, max 50)
- `cantidad`
- `precio_unitario`
- `descuento` (Opcional)
- `precio_total_sin_impuesto`
- `detalles_adicionales` (EmbedsMany Opcional)
- `impuestos` (EmbedsMany)

### Bloque de Reembolsos (Si Aplica)
El schema raíz puede contener opcionalmente un bloque `<reembolsos>` compuesto por múltiples `<reembolsoDetalle>`, los cuales contienen toda la información del documento original.

## 3. Serialización XML (`to_doc/to_xml`)

- El nodo principal debe ser `<liquidacionCompra id="comprobante" version="1.1.0">`. (Ojo, el spec de la tabla dice `versión` con tilde pero se usará `version` por estándar XML, a menos que el validador SRI exija explícitamente la tilde).
- Las reglas de omisión de `nil` son críticas en `<infoLiquidacionCompra>` (especialmente para los campos de reembolso a nivel global).
- Orden de bloques raíz:
  1. `<infoTributaria>`
  2. `<infoLiquidacionCompra>`
  3. `<detalles>`
  4. `<reembolsos>` (Opcional)
  5. `<maquinaFiscal>` (Opcional)
  6. `<infoAdicional>` (Opcional)

## 4. Plan de Pruebas

1. **Fixture Testing:** Crear un fixture XML de una Liquidación de Compra sin reembolsos, y otro con reembolsos completos.
2. **Validación de Clave:** `tipo_comprobante: 3`.
3. **Sandbox E2E:** Enviar al entorno de pruebas SRI y verificar autorización.
