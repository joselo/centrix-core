# Plan de Implementación: Consulta de Catastro SRI (RUC)

## 1. Objetivo
Implementar un cliente para el servicio REST de catastro del SRI que permita obtener información oficial de un contribuyente a partir de su número de RUC. Esta funcionalidad servirá para validar y autocompletar datos de clientes en las aplicaciones host.

## 2. Endpoint Técnico
- **URL:** `https://srienlinea.sri.gob.ec/sri-catastro-sujeto-servicio-internet/rest/ConsolidadoContribuyente/obtenerPorNumerosRuc?ruc=`
- **Método:** `GET`
- **Formato de Respuesta:** JSON (Array de objetos)

## 3. Estructura del Módulo
- **Módulo:** `CentrixCore.RucClient`
- **Archivo:** `lib/ruc_client.ex`

## 4. Definición de la Interfaz

### `get_info(ruc)`
Recibe un string de 13 dígitos y retorna:
- `{:ok, %CentrixCore.Dataset.RucInfo{}}` si el RUC existe.
- `{:error, :not_found}` si el RUC no existe en el catastro.
- `{:error, reason}` en caso de fallos de red o del servidor SRI.

## 5. Mapeo de Campos (JSON -> Elixir)
El JSON del SRI se mapeará a un struct interno para mantener la consistencia del lenguaje:

| JSON SRI | Elixir Struct Field | Notas |
|---|---|---|
| `numeroRuc` | `ruc` | |
| `razonSocial` | `razon_social` | |
| `estadoContribuyenteRuc` | `estado` | ACTIVO / SUSPENDIDO |
| `tipoContribuyente` | `tipo` | PERSONA NATURAL / SOCIEDAD |
| `regimen` | `regimen` | RIMPE / GENERAL |
| `obligadoLlevarContabilidad` | `obligado_contabilidad` | SI / NO |
| `agenteRetencion` | `agente_retencion` | SI / NO |
| `contribuyenteEspecial` | `contribuyente_especial` | SI / NO |

## 6. Implementación Técnica
1. **HTTP Client:** Usar `HTTPoison` con los mismos headers de `gzip` y timeouts que ya usamos en `CentrixCore.Ws.Client`.
2. **Parser JSON:** Usar `Poison.decode!/1` o `Jason` para procesar la respuesta.
3. **Seguridad:** Asegurar que el RUC pase la validación de formato antes de realizar la petición HTTP para evitar llamadas innecesarias.

## 7. Plan de Pruebas
1. **Mocking:** Usar `Mimic` para simular las respuestas del SRI en los tests unitarios.
2. **Caso Exitoso:** Validar que un RUC real (ej. `1103671804001`) devuelva los datos esperados.
3. **Caso No Encontrado:** Validar que un RUC inexistente devuelva `{:error, :not_found}`.
4. **Caso de Error de Red:** Validar el comportamiento ante un `timeout`.
