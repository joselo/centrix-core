# Refactorización de Lógica RIDE (XML Parser y PDF Builder)

Este documento analiza la necesidad de refactorizar los módulos de procesamiento de XML y generación de PDF en `compritas-core` para soportar múltiples tipos de comprobantes electrónicos del SRI (Facturas, Notas de Crédito, Notas de Débito, etc.).

## Estado Actual

Actualmente, los módulos `BillingCore.InvoiceXmlParser` y `BillingCore.InvoicePdfBuilder` están acoplados exclusivamente al tipo de documento "Factura" (Código 01).

- **`InvoiceXmlParser`**: Accede directamente a la clave `["factura"]` del mapa generado desde el XML.
- **`InvoicePdfBuilder`**: Renderiza etiquetas fijas como "FACTURA" y asume una estructura de ítems y pagos propia de una factura comercial.

## Análisis de Extensibilidad

El proyecto planea soportar los siguientes documentos (basado en las ramas existentes):
- **01**: Factura (Implementado)
- **04**: Nota de Crédito (En proceso)
- **05**: Nota de Débito (Planificado)
- **06**: Guía de Remisión (Planificado)
- **07**: Comprobante de Retención (Planificado)
- **03**: Liquidación de Compra (Planificado)

### ¿Refactorizar o Crear Nuevos Módulos?

Tras analizar la estructura de los documentos del SRI, se recomienda un **enfoque híbrido: Motor Genérico con Despacho Dinámico**.

**¿Por qué no crear módulos totalmente nuevos?**
Crear un `CreditNotePdfBuilder`, `DebitNotePdfBuilder`, etc., resultaría en una duplicación de código de aproximadamente el 80%. Todos los RIDE comparten:
1.  **Cabecera**: Datos de la empresa (RUC, Razón Social, Dirección Matriz/Establecimiento).
2.  **Bloque de Autorización**: Clave de acceso, número de autorización, ambiente, emisión, código de barras.
3.  **Bloque de Información Adicional**: Tabla de campos adicionales al final del documento.
4.  **Lógica de Formateo**: Conversión de montos, fechas y manejo de decimales.

**Propuesta de Refactorización:**

1.  **Módulo de Parsing Genérico (`BillingCore.DocumentXmlParser`)**:
    - Identificar el tipo de documento analizando la raíz del XML (`factura`, `notaCredito`, `notaDebito`, etc.).
    - Extraer la `infoTributaria` de forma común (es idéntica para todos).
    - Delegar la extracción de `detalles` e `infoEspecifica` a submódulos según el código de documento.

2.  **Módulo de PDF Polimórfico (`BillingCore.RidePdfBuilder`)**:
    - **Base Template**: Un motor que renderiza el "marco" del RIDE (cabecera, info tributaria, bloque de autorización y pie de página con info adicional).
    - **Content Blocks**: Definir un comportamiento o protocolo para renderizar el bloque central (la tabla de ítems varía: una Guía de Remisión tiene destinatarios, una Retención tiene impuestos retenidos).
    - **Traducción de Etiquetas**: Usar un mapa de tipos para cambiar el título del documento ("FACTURA", "NOTA DE CRÉDITO", etc.).

## Pasos para el Refactor (Considierando Notas de Crédito)

### Fase 1: Generalización del Parser
- Renombrar (o crear un alias para) `InvoiceXmlParser` a `DocumentXmlParser`.
- Modificar `parse_xml/1` para detectar la etiqueta raíz.
- Implementar el soporte para `notaCredito`, extrayendo campos obligatorios adicionales: `codDocModificado`, `numDocModificado`, `fechaEmisionDocSustento` y `motivo`.

### Fase 2: Generalización del PDF Builder
- Extraer la lógica de `add_header` y `add_footer` a funciones que no dependan del término "invoice".
- Implementar una lógica de selección de título basada en el código de documento.
- Para Notas de Crédito, añadir un bloque visual (generalmente debajo de la información del cliente) que muestre los datos del "Comprobante que se modifica".

## Conclusión

Realizar un refactor hacia un motor genérico en este punto es fundamental. Continuar con el enfoque actual de "solo facturas" generará una deuda técnica significativa al implementar los siguientes 5 tipos de documentos. La similitud visual y estructural de los comprobantes del SRI justifica plenamente una arquitectura compartida en `compritas-core`.
