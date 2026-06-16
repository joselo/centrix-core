# Plan de Implementación: Anexo de Gastos Personales (GP)

## 1. Objetivo
Implementar un generador de archivos XML para el **Anexo de Gastos Personales**, permitiendo a personas naturales reportar sus gastos deducibles anuales al SRI de acuerdo con la normativa vigente.

## 2. Estructura del XML
A diferencia de otros documentos, el Anexo GP tiene una estructura plana y simplificada:
- **Nodo Raíz:** `<anexoGastosPersonales>`
- **Versión:** Generalmente `1.0` (o según la última ficha técnica vigente).

## 3. Definición de Ecto Schemas

### `CentrixCore.Dataset.AnexoGp.Cabecera`
Información del informante y resumen:
- `anio`: (Año fiscal, ej: 2025)
- `tipo_id_informante`: (C para Cédula, R para RUC, P para Pasaporte)
- `id_informante`: (Número de identificación)
- `total_gastos`: (Suma total de todos los rubros)
- `total_base_imponible`: (Suma de bases imponibles)

### `CentrixCore.Dataset.AnexoGp.Detalle`
Mapea el bloque `<detalleAnexo> -> <itemAnexo>`.
- `ruc_proveedor`: (RUC del establecimiento donde se hizo el gasto)
- `valor_gasto`: (Monto total del gasto en esa categoría)
- `tipo_gasto`: (Código de categoría)

#### Categorías Vigentes (`tipo_gasto`):
| Código | Categoría |
|---|---|
| `V` | Vivienda |
| `S` | Salud |
| `E` | Educación, Arte y Cultura |
| `A` | Alimentación |
| `T` | Vestimenta |
| `U` | Turismo |

## 4. Punto de Entrada
- **Módulo:** `lib/anexo_gp_builder.ex`
- **Función:** `build_anexo(params)` -> `{:ok, xml_string}`

## 5. Lógica de Negocio
1. **Agregación por Proveedor/Tipo:** Si existen 10 facturas de "Supermaxi" en la categoría "Alimentación", el anexo debe consolidarlas en un solo registro detallando el RUC del proveedor y la suma total de esas 10 facturas.
2. **Validación de Identificación:** El ID del informante debe ser validado (Módulo 10).
3. **Validación de Año:** Solo se permiten reportes de años fiscales cerrados o el año en curso.

## 6. Plan de Pruebas
1. **Generación de XML básico:** Con un solo gasto en cada categoría.
2. **Prueba de Consolidación:** Pasar una lista de 50 facturas y verificar que el XML resultante agrupe correctamente por RUC de proveedor y código de gasto.
3. **Validación de Formato:** Asegurar que los montos tengan 2 decimales.
