# Plan de Implementación: Anexo Transaccional Simplificado (ATS)

## 1. Objetivo
Implementar un generador de archivos XML para el **Anexo Transaccional Simplificado (ATS)** que permita a las aplicaciones host consolidar sus operaciones de compras, ventas y anulados en un único archivo compatible con el validador del SRI.

## 2. Requisitos Previos
> [!IMPORTANT]
> Este módulo requiere que las ramas de `nota_debito`, `guia_remision`, `comprobante_retencion` y `liquidacion_compra` estén fusionadas en `master`, ya que el ATS utiliza los códigos y validaciones definidos en todos esos documentos.

## 3. Estructura del Módulo
- **Punto de Entrada:** `lib/ats_builder.ex`
- **Carpeta de Schemas:** `lib/xml_builder/dataset/ats/`
- **Carpeta de Tests:** `test/ats_builder_test.exs`

## 4. Definición de Ecto Schemas

### `BillingCore.Dataset.Ats.Iva` (Raíz)
Representa el nodo `<iva>`.
- `tipo_id_informante`: (R, RUC)
- `id_informante`: (RUC del emisor)
- `razon_social`: (Razón social)
- `anio`: (Año del reporte)
- `mes`: (Mes del reporte, "01" a "12")
- `num_estab_ruc`: (Número de establecimientos activos)
- `total_ventas`: (Suma total de base gravada + base 0 + no objeto de ventas)
- `codigo_operativo`: ("IVA")

### `BillingCore.Dataset.Ats.Compra`
Mapea el bloque `<detalleCompras> -> <detalleCompra>`.
- `cod_sustento`: (Código de sustento tributario)
- `tp_id_prov`: (Tipo ID proveedor)
- `id_prov`: (Identificación)
- `tipo_comprobante`: (Código SRI del documento recibido)
- `fecha_registro`: (dd/mm/yyyy)
- `establecimiento`, `punto_emision`, `secuencial`
- `fecha_emision`
- `autorizacion`: (Clave de acceso o número de autorización)
- `base_no_gra_iva`, `base_imponible`, `base_imp_grav`, `base_imp_exe`
- `monto_ice`, `monto_iva`
- `valor_ret_bienes`, `valor_ret_servicios`, `val_ret_serv_100` (Retenciones de IVA)
- `pago_loc_ext`, `tipo_regi`, `pais_efec_pago`, `aplic_conv_dob_trib`, `pag_ext_suj_ret_nor_leg`
- **EmbedsMany:** `detalles_air` (Retenciones en la Fuente)
- **EmbedsMany:** `formas_de_pago`

### `BillingCore.Dataset.Ats.Venta`
Mapea el bloque `<detalleVentas> -> <detalleVenta>`.
- `tp_id_cliente`, `id_cliente`
- `tipo_comprobante`, `tipo_emision`
- `numero_comprobantes`: (Cantidad de documentos para este cliente/tipo)
- `base_no_gra_iva`, `base_imponible`, `base_imp_grav`, `monto_iva`, `monto_ice`
- `valor_ret_iva`, `valor_ret_renta`
- **EmbedsMany:** `formas_de_pago`

### `BillingCore.Dataset.Ats.Anulado`
Mapea el bloque `<detalleAnulados> -> <detalleAnulado>`.
- `tipo_comprobante`
- `establecimiento`, `punto_emision`
- `secuencial_inicio`, `secuencial_fin`
- `autorizacion`

## 5. Lógica de Agregación y Validación
A diferencia de los comprobantes electrónicos, el ATS requiere validaciones cruzadas:
1. **Validación de Totales:** El campo `totalVentas` en la cabecera debe ser la suma exacta de las bases imponibles de la sección de ventas.
2. **Validación de Fechas:** Todas las transacciones deben pertenecer al `mes` y `anio` declarados.
3. **Formato de Números:** 2 decimales fijos.

## 6. Serialización XML
- El archivo NO requiere firma digital XAdES-BES.
- Debe generar la declaración XML estándar: `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`.
- El nodo raíz es `<iva>`.

## 7. Plan de Pruebas
1. **Prueba de Reporte Vacío:** Generar un ATS sin transacciones (solo cabecera).
2. **Prueba de Compras con Retención:** Validar que el bloque `<air>` se genere correctamente.
3. **Prueba de Ventas Agregadas:** Validar que múltiples facturas al mismo cliente se sumen correctamente en un solo nodo `<detalleVenta>`.
4. **Validación con DIMM:** (Manual) Cargar el XML generado en el software DIMM Formularios del SRI para verificar que no haya errores estructurales.
