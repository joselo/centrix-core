# Especificación XML Comprobantes Electrónicos SRI Ecuador

> **Propósito para agente IA:** Este documento define los campos, tipos de dato, longitudes máximas y obligatoriedad de cada campo según el formato XML oficial del SRI Ecuador. Úsalo para verificar y actualizar los esquemas Ecto del proyecto, agregando validaciones con `validate_length/3`, `validate_required/2` y el tipo de campo correcto en las migraciones.

---

## Convenciones de tipos

| Tipo XML | Tipo Ecto | Tipo columna DB |
|---|---|---|
| Alfanumérico | `:string` | `varchar` o `text` |
| Numérico (entero) | `:integer` | `integer` |
| Numérico (decimal) | `:decimal` | `numeric` |
| Fecha (dd/mm/aaaa) | `:date` | `date` |
| Fecha (mm/aaaa) | `:string` | `varchar(7)` |
| Texto SI/NO | `:string` | `varchar(2)` |
| Alfabético SI/NO | `:string` | `varchar(2)` |

---

## Campos compartidos — `infoTributaria`

Presentes en **todos** los tipos de comprobante.

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `ambiente` | Sí | Numérico | 1 | Tabla 4 Ficha Técnica |
| `tipoEmision` | Sí | Numérico | 1 | Tabla 2 Ficha Técnica |
| `razonSocial` | Sí | Alfanumérico | Max 300 | |
| `nombreComercial` | Opcional | Alfanumérico | Max 300 | |
| `ruc` | Sí | Numérico | 13 (exacto) | |
| `claveAcceso` | Sí | Numérico | 49 (exacto) | Tabla 1 |
| `codDoc` | Sí | Numérico | 2 | Tabla 3 |
| `estab` | Sí | Numérico | 3 (exacto) | |
| `ptoEmi` | Sí | Numérico | 3 (exacto) | |
| `secuencial` | Sí | Numérico | 9 (exacto) | |
| `dirMatriz` | Sí | Alfanumérico | Max 300 | |

---

## 1. Factura — Versión 2.1.0

### 1.1 `infoFactura`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `fechaEmision` | Sí | Fecha | dd/mm/aaaa | |
| `dirEstablecimiento` | Opcional | Alfanumérico | Max 300 | |
| `contribuyenteEspecial` | Opcional | Alfanumérico | Min 3, Max 13 | |
| `obligadoContabilidad` | Opcional | Texto | SI/NO | |
| `tipoIdentificacionComprador` | Sí | Numérico | 2 | Tabla 6 |
| `razonSocialComprador` | Sí | Alfanumérico | Max 300 | |
| `identificacionComprador` | Sí | Numérico | Max 13 | |
| `direccionComprador` | Opcional | Alfanumérico | Max 300 | |
| `totalSinImpuestos` | Sí | Numérico | Max 14 | |
| `totalDescuento` | Sí | Numérico | Max 14 | |
| `propina` | Sí | Numérico | Max 14 | |
| `importeTotal` | Sí | Numérico | Max 14 | |
| `moneda` | Opcional | Alfanumérico | Max 15 | |
| `valorRetIva` | Opcional | Numérico | Max 14 | |
| `valorRetRenta` | Opcional | Numérico | Max 14 | |

### 1.2 `totalConImpuestos` → `totalImpuesto`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigo` | Sí | Numérico | 1 | Tabla 16 |
| `codigoPorcentaje` | Sí | Numérico | Min 1, Max 4 | Tabla 17 |
| `baseImponible` | Sí | Numérico | Max 14 | |
| `valor` | Sí | Numérico | Max 14 | |

### 1.3 `pagos` → `pago`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `formaPago` | Sí | Numérico | 2 | Tabla 24 |
| `total` | Sí | Numérico | Max 14 | |
| `plazo` | Opcional | Numérico | Max 14 | |
| `unidadTiempo` | Opcional | Texto | Max 10 | |

### 1.4 `detalles` → `detalle`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigoPrincipal` | Sí | Alfanumérico | Max 25 | |
| `codigoAuxiliar` | Opcional | Alfanumérico | Max 25 | |
| `descripcion` | Sí | Alfanumérico | Max 300 | |
| `cantidad` | Sí | Numérico | Max 18, hasta 6 decimales | |
| `precioUnitario` | Sí | Numérico | Max 18, hasta 6 decimales | |
| `descuento` | Sí | Numérico | Max 14 | |
| `precioTotalSinImpuesto` | Sí | Numérico | Max 14 | |

### 1.5 `detalles` → `detalle` → `impuestos` → `impuesto`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigo` | Sí | Numérico | 1 | Tabla 16 |
| `codigoPorcentaje` | Sí | Numérico | Min 1, Max 4 | Tabla 17 |
| `tarifa` | Sí | Numérico | Min 1 Max 4 / 2 enteros, 2 decimales | |
| `baseImponible` | Sí | Numérico | Max 14 | |
| `valor` | Sí | Numérico | Max 14 | |

### 1.6 `otrosRubrosTerceros` → `rubro`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `concepto` | Sí | Alfanumérico | Max 300 | |
| `total` | Sí | Numérico | Min 1, Max 4 | |

### 1.7 `infoAdicional` → `campoAdicional`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `nombre` (atributo) | Opcional | Alfanumérico | Max 300 | |
| valor (contenido) | Opcional | Alfanumérico | Max 300 | |

---

## 2. Nota de Crédito — Versión 1.1.0

### 2.1 `infoNotaCredito`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `fechaEmision` | Sí | Fecha | dd/mm/aaaa | |
| `dirEstablecimiento` | Opcional | Alfanumérico | Max 300 | |
| `tipoIdentificacionComprador` | Sí | Numérico | 2 | Tabla 6 |
| `razonSocialComprador` | Sí | Alfanumérico | Max 300 | |
| `identificacionComprador` | Sí | Alfanumérico | Max 20 | |
| `contribuyenteEspecial` | Opcional | Alfanumérico | Min 3, Max 13 | |
| `obligadoContabilidad` | Opcional | Texto | SI/NO | |
| `rise` | Opcional | Alfanumérico | Max 40 | |
| `codDocModificado` | Sí | Numérico | 2 | Tabla 3 |
| `numDocModificado` | Opcional | Numérico | 15 | |
| `fechaEmisionDocSustento` | Sí | Fecha | dd/mm/aaaa | |
| `totalSinImpuestos` | Sí | Numérico | Max 14 | |
| `valorModificacion` | Sí | Numérico | Max 14 | |
| `moneda` | Opcional | Alfanumérico | Max 15 | |

### 2.2 `totalConImpuestos` → `totalImpuesto`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigo` | Sí | Numérico | 1 | Tabla 16 |
| `codigoPorcentaje` | Sí | Numérico | Min 1, Max 4 | Tabla 17 o 18 |
| `baseImponible` | Sí | Numérico | Max 14 | |
| `valor` | Sí | Numérico | Max 14 | |

### 2.3 `motivo`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `motivo` | Sí | Alfanumérico | Max 300 | Razón de la nota de crédito |

### 2.4 `detalles` → `detalle`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigoInterno` | Opcional | Alfanumérico | Max 25 | |
| `codigoAdicional` | Opcional | Alfanumérico | Max 25 | |
| `descripcion` | Sí | Alfanumérico | Max 300 | |
| `cantidad` | Sí | Numérico | Max 18, hasta 6 decimales | |
| `precioUnitario` | Sí | Numérico | Max 18, hasta 6 decimales | |
| `descuento` | Opcional | Numérico | Max 14 | |
| `precioTotalSinImpuesto` | Sí | Numérico | Max 14 | |

### 2.5 `detalles` → `detalle` → `impuestos` → `impuesto`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigo` | Sí | Numérico | 1 | Tabla 16 |
| `codigoPorcentaje` | Sí | Numérico | Min 1, Max 4 | Tabla 17 o 18 |
| `tarifa` | Sí | Numérico | Min 1, Max 4 / 2 enteros, 2 decimales | |
| `baseImponible` | Sí | Numérico | Max 14 | |
| `valor` | Sí | Numérico | Max 14 | |

### 2.6 `detallesAdicionales` → `detAdicional`

| Atributo | Obligatorio | Tipo | Longitud | Notas |
|---|---|---|---|---|
| `nombre` | Opcional | Alfanumérico | Max 300 | |
| `valor` | Opcional | Alfanumérico | Max 300 | |

### 2.7 `infoAdicional` → `campoAdicional`

| Campo | Obligatorio | Tipo | Longitud | Notas |
|---|---|---|---|---|
| `nombre` (atributo) | Opcional | Alfanumérico | Max 300 | |
| valor (contenido) | Opcional | Alfanumérico | Max 300 | |

---

## 3. Nota de Débito — Versión 1.0.0

### 3.1 `infoNotaDebito`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `fechaEmision` | Sí | Fecha | dd/mm/aaaa | |
| `dirEstablecimiento` | Opcional | Alfanumérico | Max 300 | |
| `tipoIdentificacionComprador` | Sí | Numérico | 2 | Tabla 6 |
| `razonSocialComprador` | Sí | Alfanumérico | Max 300 | |
| `identificacionComprador` | Sí | Alfanumérico | Max 20 | |
| `contribuyenteEspecial` | Opcional | Alfanumérico | Min 3, Max 13 | |
| `obligadoContabilidad` | Sí | Texto | SI/NO | |
| `codDocModificado` | Sí | Numérico | 2 | Tabla 3 |
| `numDocModificado` | Sí | Numérico | 15 | |
| `fechaEmisionDocSustento` | Sí | Fecha | dd/mm/aaaa | |
| `totalSinImpuestos` | Sí | Numérico | Max 14 | |

### 3.2 `impuestos` → `impuesto`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigo` | Sí | Numérico | 1 | Tabla 16 |
| `codigoPorcentaje` | Sí | Numérico | Min 1, Max 4 | Tabla 17 |
| `tarifa` | Sí | Numérico | Min 1 Max 4 / 2 enteros, 2 decimales | |
| `baseImponible` | Sí | Numérico | Max 14 | |
| `valor` | Sí | Numérico | Max 14 | |

### 3.3 `pagos` → `pago`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `formaPago` | Sí | Numérico | 2 | Tabla 24 |
| `total` | Sí | Numérico | Max 14 | |
| `plazo` | Opcional | Numérico | Max 14 | |
| `unidadTiempo` | Opcional | Texto | Max 10 | |

### 3.4 `valorTotal`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `valorTotal` | Sí | Numérico | Max 14 | |

### 3.5 `motivos` → `motivo`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `razon` | Sí | Alfanumérico | Max 300 | |
| `valor` | Sí | Alfanumérico | Max 300 | |

### 3.6 `infoAdicional` → `campoAdicional`

| Campo | Obligatorio | Tipo | Longitud | Notas |
|---|---|---|---|---|
| `nombre` (atributo) | Opcional | Alfanumérico | Max 300 | |
| valor (contenido) | Opcional | Alfanumérico | Max 300 | |

---

## 4. Guía de Remisión — Versión 1.0.0

### 4.1 `infoGuiaRemision`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `dirEstablecimiento` | Opcional | Alfanumérico | Max 300 | |
| `dirPartida` | Sí | Alfanumérico | Max 300 | |
| `razonSocialTransportista` | Sí | Alfanumérico | Max 300 | |
| `tipoIdentificacionTransportista` | Sí | Numérico | 2 | Tabla 6 |
| `rucTransportista` | Sí | Alfanumérico | Max 13 | |
| `rise` | Opcional | Alfanumérico | Max 40 | |
| `obligadoContabilidad` | Opcional | Texto | SI/NO | |
| `contribuyenteEspecial` | Opcional | Alfanumérico | Min 3, Max 13 | |
| `fechaIniTransporte` | Sí | Fecha | dd/mm/aaaa | |
| `fechaFinTransporte` | Sí | Fecha | dd/mm/aaaa | |
| `placa` | Sí | Alfanumérico | Max 20 | |

### 4.2 `destinatarios` → `destinatario`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `identificacionDestinatario` | Sí | Alfanumérico | Max 20 | |
| `razonSocialDestinatario` | Sí | Alfanumérico | Max 300 | |
| `dirDestinatario` | Sí | Alfanumérico | Max 300 | |
| `motivoTraslado` | Sí | Alfanumérico | Max 300 | |
| `docAduaneroUnico` | Opcional | Alfanumérico | Max 20 | |
| `codEstabDestino` | Opcional | Numérico | 3 | |
| `ruta` | Sí | Alfanumérico | Max 300 | |
| `codDocSustento` | Opcional | Numérico | 2 | Tabla 3 |
| `numDocSustento` | Opcional | Numérico | 15 | |
| `numAutDocSustento` | Opcional | Numérico | 10, 37 o 49 | |
| `fechaEmisionDocSustento` | Sí | Fecha | dd/mm/aaaa | |

### 4.3 `destinatario` → `detalles` → `detalle`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigoInterno` | Opcional | Alfanumérico | Max 25 | |
| `codigoAdicional` | Opcional | Alfanumérico | Max 25 | |
| `descripcion` | Sí | Alfanumérico | Max 300 | |
| `cantidad` | Sí | Numérico | Max 14 | |

### 4.4 `detallesAdicionales` → `detAdicional`

| Atributo | Obligatorio | Tipo | Longitud | Notas |
|---|---|---|---|---|
| `nombre` | Opcional | Alfanumérico | Max 300 | |
| `valor` | Opcional | Alfanumérico | Max 300 | |

### 4.5 `infoAdicional` → `campoAdicional`

| Campo | Obligatorio | Tipo | Longitud | Notas |
|---|---|---|---|---|
| `nombre` (atributo) | Opcional | Alfanumérico | Max 300 | |
| valor (contenido) | Opcional | Alfanumérico | Max 300 | |

---

## 5. Liquidación de Compra — Versión 1.1.0

### 5.1 `infoLiquidacionCompra`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `fechaEmision` | Sí | Fecha | dd/mm/aaaa | |
| `dirEstablecimiento` | Opcional | Alfanumérico | Max 300 | |
| `contribuyenteEspecial` | Opcional | Alfanumérico | Min 3, Max 13 | |
| `obligadoContabilidad` | Opcional | Texto | SI/NO | |
| `tipoIdentificacionProveedor` | Opcional | Numérico | 2 | Tabla 6 |
| `razonSocialProveedor` | Sí | Alfanumérico | Max 300 | |
| `identificacionProveedor` | Sí | Numérico | Max 20 | |
| `direccionProveedor` | Opcional | Alfanumérico | Max 300 | |
| `totalSinImpuestos` | Sí | Numérico | Max 14 | |
| `totalDescuento` | Opcional | Numérico | Max 14 | |
| `codDocReembolso` | Sí (si aplica) | Numérico | Max 2 | Obligatorio si corresponde reembolso |
| `totalComprobantesReembolso` | Sí (si codDocReembolso=41) | Numérico | Max 14 | |
| `totalBaseImponibleReembolso` | Sí (si codDocReembolso=41) | Numérico | Max 14 | |
| `totalImpuestoReembolso` | Sí (si codDocReembolso=41) | Numérico | Max 14 | |
| `importeTotal` | Sí | Numérico | Max 14 | |
| `moneda` | Sí | Alfanumérico | Max 14 | |

### 5.2 `totalConImpuestos` → `totalImpuesto`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigo` | Sí | Numérico | Max 2 | Tabla 16 |
| `codigoPorcentaje` | Sí | Numérico | Max 2 | Tabla 17 |
| `descuentoAdicional` | Opcional | Numérico | Max 14 | |
| `baseImponible` | Sí | Numérico | Max 14 | |
| `tarifa` | Sí | Numérico | Min 1 Max 4 / 2 enteros, 2 decimales | |
| `valor` | Sí | Numérico | Max 14 | |

### 5.3 `pagos` → `pago`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `formaPago` | Sí | Numérico | Max 2 | Tabla 24 |
| `total` | Sí | Numérico | Max 14 | |
| `plazo` | Sí | Numérico | Max 14 | |
| `unidadTiempo` | Opcional | Texto | Max 10 | |

### 5.4 `detalles` → `detalle`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigoPrincipal` | Sí | Alfanumérico | Max 25 | |
| `codigoAuxiliar` | Opcional | Alfanumérico | Max 25 | |
| `descripcion` | Sí | Alfanumérico | Max 300 | |
| `unidadMedida` | Opcional | Alfanumérico | Max 50 | |
| `cantidad` | Sí | Numérico | Max 14 | |
| `precioUnitario` | Sí | Numérico | Max 14 | |
| `descuento` | Opcional | Numérico | Max 14 | |
| `precioTotalSinImpuesto` | Sí | Numérico | Max 14 | |

### 5.5 `detalle` → `impuestos` → `impuesto`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigo` | Sí | Numérico | Max 2 | Tabla 16 |
| `codigoPorcentaje` | Sí | Numérico | Max 2 | Tabla 17 |
| `tarifa` | Sí | Numérico | Min 1 Max 4 / 2 enteros, 2 decimales | |
| `baseImponible` | Sí | Numérico | Max 14 | |
| `valor` | Sí | Numérico | Max 14 | |

### 5.6 `reembolsos` → `reembolsoDetalle`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `tipoIdentificacionProveedorReembolso` | Sí (si codDocReembolso=41) | Numérico | 2 | Tabla 6 |
| `identificacionProveedorReembolso` | Sí (si codDocReembolso=41) | Numérico | Max 20 | |
| `codPaisPagoProveedorReembolso` | Sí (si codDocReembolso=41) | Numérico | Max 3 | Tabla 25 |
| `tipoProveedorReembolso` | Sí (si codDocReembolso=41) | Numérico | 2 | Tabla 26 |
| `codDocReembolso` | Sí (si codDocReembolso=41) | Numérico | Max 3 | Tabla 3 |
| `estabDocReembolso` | Sí (si codDocReembolso=41) | Numérico | Max 3 | |
| `ptoEmiDocReembolso` | Sí (si codDocReembolso=41) | Numérico | Max 3 | |
| `secuencialDocReembolso` | Sí (si codDocReembolso=41) | Numérico | Max 9 | |
| `fechaEmisionDocReembolso` | Sí (si codDocReembolso=41) | Fecha | dd/mm/aaaa | |
| `numeroAutorizacionDocReemb` | Sí (si codDocReembolso=41) | Numérico | 10, 37 o 49 | |

### 5.7 `reembolsoDetalle` → `detalleImpuestos` → `detalleImpuesto`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigo` | Sí (si codDocReembolso=41) | Numérico | Max 2 | Tabla 16 |
| `codigoPorcentaje` | Sí (si codDocReembolso=41) | Numérico | Max 2 | Tabla 17 |
| `tarifa` | Sí (si codDocReembolso=41) | Numérico | Min 1 Max 4 / 2 enteros, 2 decimales | |
| `baseImponibleReembolso` | Sí (si codDocReembolso=41) | Numérico | Max 14 | |
| `impuestoReembolso` | Sí (si codDocReembolso=41) | Numérico | Max 14 | |

### 5.8 `maquinaFiscal`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `marca` | Opcional | Alfanumérico | Min 1, Max 100 | |
| `modelo` | Opcional | Alfanumérico | Min 1, Max 100 | |
| `serie` | Opcional | Alfanumérico | Max 30 | |

### 5.9 `infoAdicional` → `campoAdicional`

| Campo | Obligatorio | Tipo | Longitud | Notas |
|---|---|---|---|---|
| `nombre` (atributo) | Opcional | Alfanumérico | Max 300 | |
| valor (contenido) | Opcional | Alfanumérico | Max 300 | |

---

## 6. Comprobante de Retención ATS — Versión 2.0.0

### 6.1 `infoCompRetencion`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `fechaEmision` | Sí | Fecha | dd/mm/aaaa | |
| `dirEstablecimiento` | Opcional | Alfanumérico | Max 300 | |
| `contribuyenteEspecial` | Opcional | Alfanumérico | Min 3, Max 13 | |
| `obligadoContabilidad` | Opcional | Texto | SI/NO | |
| `tipoIdentificacionSujetoRetenido` | Sí | Numérico | 2 | Tabla 6 |
| `tipoSujetoRetenido` | Sí (condicional) | Numérico | 2 | Sólo si tipoIdentificacion = IDENTIFICACION DEL EXTERIOR |
| `parteRel` | Sí | Alfabético | SI/NO (2) | |
| `razonSocialSujetoRetenido` | Sí | Alfanumérico | Max 300 | |
| `identificacionSujetoRetenido` | Sí | Alfanumérico | Max 20 | |
| `periodoFiscal` | Sí | Fecha | mm/aaaa | |

### 6.2 `docsSustento` → `docSustento`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codSustento` | Sí | Numérico | 2 | Tabla 5 Catálogo ATS |
| `codDocSustento` | Sí | Numérico | Min 2, Max 3 | Tabla 4 Catálogo ATS |
| `numDocSustento` | Opcional | Numérico | 15 | |
| `fechaEmisionDocSustento` | Sí | Fecha | dd/mm/aaaa | |
| `fechaRegistroContable` | Opcional | Fecha | dd/mm/aaaa | |
| `numAutDocSustento` | Opcional | Numérico | 10, 37 o 49 | |
| `pagoLocExt` | Sí | Numérico | 2 | Tabla 15 Catálogo ATS |
| `tipoRegi` | Sí (si pagoLocExt=02) | Numérico | 2 | Tabla 19 Catálogo ATS |
| `paisEfecPago` | Sí (condicional) | Numérico | 3 o 4 | Ver reglas imagen 2 |
| `aplicConvDobTrib` | Sí (si pagoLocExt=02) | Texto | SI/NO | |
| `pagExtSujRetNorLeg` | Sí (si aplicConvDobTrib=NO) | Texto | SI/NO | |
| `pagoRegFis` | Sí (si pagoLocExt=02) | Numérico | 2 | Valor SI |
| `totalComprobantesReembolso` | Sí (si codSustento=41) | Numérico | Max 14 | |
| `totalBaseImponibleReembolso` | Sí (si codSustento=41) | Numérico | Max 14 | |
| `totalImpuestoReembolso` | Sí (si codSustento=41) | Numérico | Max 14 | |
| `totalSinImpuestos` | Sí | Numérico | Max 14 | |
| `importeTotal` | Sí | Numérico | Max 14 | |

### 6.3 `docSustento` → `impuestosDocSustento` → `impuestoDocSustento`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codImpuestoDocSustento` | Sí | Numérico | 1 | Tabla 16 Ficha Técnica |
| `codigoPorcentaje` | Sí | Numérico | Min 1, Max 4 | Tabla 17 o 18 Ficha Técnica |
| `baseImponible` | Sí | Numérico | Max 14 | |
| `tarifa` | Sí | Numérico | Max 3 enteros y 2 decimales | |
| `valorImpuesto` | Sí | Numérico | Max 14 | |

### 6.4 `retenciones` → `retencion`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigo` | Sí | Numérico | 1 | Tabla 19 Ficha Técnica |
| `codigoRetencion` | Sí | Numérico | Min 1, Max 5 | Tabla 20 Ficha Técnica |
| `baseImponible` | Sí | Numérico | Max 14 | |
| `porcentajeRetener` | Sí | Numérico | Min 1 Max 5 (enteros y decimales) | Tabla 20 Ficha Técnica |
| `valorRetenido` | Sí | Numérico | Max 12 enteros y 2 decimales | |
| `fechaPagoDiv` | Sí (si codSustento=10) | Fecha | dd/mm/aaaa | Solo dividendos |
| `imRentaSoc` | Sí (si codSustento=10) | Numérico | Max 14 enteros y 2 decimales | Solo dividendos |
| `ejerFisUtDiv` | Sí (si codSustento=10) | Numérico | 4 | Solo dividendos |
| `numCajBan` | Sí (condicional) | Numérico | Max 7 enteros | Solo si codigoRetencion = 338, 340, 341, 342, 342A, 342B |
| `precCajBan` | Sí (condicional) | Numérico | Max 12 enteros y 2 decimales | Solo si codigoRetencion = 338, 340, 341, 342, 342A, 342B |

### 6.5 `reembolsos` → `reembolsoDetalle`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `tipoIdentificacionProveedorReembolso` | Sí (si codDocSustento=41) | Numérico | 2 | Tabla 6 Ficha Técnica |
| `identificacionProveedorReembolso` | Sí (si codDocSustento=41) | Alfanumérico | Max 20 | |
| `codPaisPagoProveedorReembolso` | Sí (si codDocSustento=41) | Numérico | 3 | Tabla 25 Ficha Técnica |
| `tipoProveedorReembolso` | Sí (si codDocSustento=41) | Numérico | 2 | Tabla 26 Ficha Técnica |
| `codDocReembolso` | Sí (si codDocSustento=41) | Numérico | 2 | Tabla 4 Catálogo ATS |
| `estabDocReembolso` | Sí (si codDocSustento=41) | Numérico | 3 | |
| `ptoEmiDocReembolso` | Sí (si codDocSustento=41) | Numérico | 3 | |
| `secuencialDocReembolso` | Sí (si codDocSustento=41) | Numérico | 9 | |
| `fechaEmisionDocReembolso` | Sí (si codDocSustento=41) | Fecha | dd/mm/aaaa | |
| `numeroAutorizacionDocReemb` | Sí (si codDocSustento=41) | Numérico | 10, 37 o 49 | |

### 6.6 `reembolsoDetalle` → `detalleImpuestos` → `detalleImpuesto`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `codigo` | Sí (si codDocSustento=41) | Numérico | 1 | Tabla 16 Ficha Técnica |
| `codigoPorcentaje` | Sí (si codDocSustento=41) | Numérico | Min 1, Max 4 | Tabla 17 o 18 Ficha Técnica |
| `tarifa` | Sí (si codDocSustento=41) | Numérico | Min 1, Max 4 | |
| `baseImponibleReembolso` | Sí (si codDocSustento=41) | Numérico | Max 14 | |
| `impuestoReembolso` | Sí (si codDocSustento=41) | Numérico | Max 14 | |

### 6.7 `pagos` → `pago`

| Campo XML | Obligatorio | Tipo | Longitud / Formato | Notas |
|---|---|---|---|---|
| `formapago` | Sí | Numérico | 2 | Tabla 13 Catálogo ATS |
| `total` | Sí | Numérico | Max 14 | |

### 6.8 `infoAdicional` → `campoAdicional`

| Campo | Obligatorio | Tipo | Longitud | Notas |
|---|---|---|---|---|
| `nombre` (atributo) | Opcional | Alfanumérico | Max 300 | |
| valor (contenido) | Opcional | Numérico | Min 1, Max 4 | |

---

## Resumen de validaciones Ecto por campo repetido

Esta sección resume las validaciones más comunes que aplican en todos o varios documentos, para no repetirlas en cada schema.

```elixir
# Campos de longitud fija — usar validate_length con min y max iguales
validate_length(:ruc, is: 13)
validate_length(:claveAcceso, is: 49)
validate_length(:estab, is: 3)
validate_length(:ptoEmi, is: 3)
validate_length(:secuencial, is: 9)

# Campos con máximo
validate_length(:razonSocial, max: 300)
validate_length(:nombreComercial, max: 300)
validate_length(:dirMatriz, max: 300)
validate_length(:dirEstablecimiento, max: 300)
validate_length(:descripcion, max: 300)
validate_length(:contribuyenteEspecial, min: 3, max: 13)
validate_length(:identificacionComprador, max: 20)
validate_length(:identificacionProveedor, max: 20)
validate_length(:codigoPrincipal, max: 25)
validate_length(:codigoAuxiliar, max: 25)
validate_length(:moneda, max: 15)
validate_length(:rise, max: 40)
validate_length(:placa, max: 20)
validate_length(:unidadTiempo, max: 10)
validate_length(:unidadMedida, max: 50)
validate_length(:numDocSustento, max: 15)
validate_length(:numDocModificado, max: 15)

# Campos SI/NO
validate_inclusion(:obligadoContabilidad, ["SI", "NO"])
validate_inclusion(:parteRel, ["SI", "NO"])
validate_inclusion(:aplicConvDobTrib, ["SI", "NO"])
validate_inclusion(:pagExtSujRetNorLeg, ["SI", "NO"])

# Campos numéricos de 1 dígito
validate_length(:ambiente, is: 1)
validate_length(:tipoEmision, is: 1)

# Campos numéricos de 2 dígitos
validate_length(:codDoc, max: 2)
validate_length(:tipoIdentificacionComprador, max: 2)
validate_length(:codDocModificado, max: 2)
validate_length(:formaPago, max: 2)
```

---

## Notas para el agente IA

1. Los campos `cantidad` y `precioUnitario` en **Factura** y **Nota de Crédito** aceptan hasta 6 decimales y hasta 18 dígitos totales. Usar `Decimal` en Ecto con precisión adecuada.
2. Los campos de montos (`totalSinImpuestos`, `importeTotal`, `valor`, etc.) son `Max 14` dígitos totales incluyendo decimales. Usar tipo `:decimal` con escala 2.
3. `numAutDocSustento` y `numeroAutorizacionDocReemb` pueden tener 10, 37 **o** 49 caracteres. Validar con una función custom que verifique esas longitudes exactas.
4. `periodoFiscal` tiene formato `mm/aaaa` — almacenar como `:string` de longitud 7.
5. Los campos `nombre` y `valor` de `campoAdicional` son pares clave-valor dinámicos. En Ecto se almacenan como `embeds_many` o tabla separada con `key` y `value`.
6. Los campos marcados como "Tabla N Ficha Técnica" o "Catálogo ATS" requieren validación de inclusión en los valores permitidos por esa tabla — esas tablas no están en este documento y deben consultarse en la Ficha Técnica Offline del SRI.