# CentrixCore

Una librería de Elixir para la generación y firma digital de documentos de facturación electrónica para Ecuador, conforme a los requisitos del SRI (*Servicio de Rentas Internas*).

## Documentación

- **[AGENTS.md](./AGENTS.md)** — Guía completa del proyecto para agentes de IA y desarrolladores (arquitectura, dominio, módulos, convenciones).
- **[docs/facturas.md](./docs/facturas.md)** — Referencia detallada de la implementación de Facturas.
- **[docs/notas_de_credito.md](./docs/notas_de_credito.md)** — Referencia detallada de la implementación de Notas de Crédito.
- **[docs/xbes.md](./docs/xbes.md)** — Implementación de la firma digital XAdES-BES.

## Características actuales

| Funcionalidad | Estado |
|---|---|
| Generación de XML — Facturas (`cod_doc = 01`) | ✅ |
| Generación de XML — Notas de Crédito (`cod_doc = 04`) | ✅ |
| Firma digital XAdES-BES (P12/PKCS#12) | ✅ |
| Envío y autorización SRI (SOAP) | ✅ |
| Parsing de XML autorizado | ✅ |
| Generación de PDF (A4) | ✅ |
| Generación de código de barras Code128 | ✅ |
| Notas de Débito, Retenciones, Guías de Remisión | 🔜 Planificado |

## Instalación

La librería no está publicada en Hex. Agrega lo siguiente a `mix.exs`:

```elixir
def deps do
  [
    {:centrix_core, github: "joselo/centrix-core", branch: "master"}
  ]
end
```

```bash
mix deps.get
```

## Uso básico

```elixir
# 1. Construir XML
{:ok, [xml: xml, clave_acceso: key]} =
  CentrixCore.XmlBuilder.build_invoice(invoice_params)

# 2. Firmar
{:ok, signed_xml} =
  CentrixCore.Signing.sign(xml, "/path/to/cert.p12", "password")

# 3. Enviar al SRI
{:ok, %{status: "RECIBIDA"}} =
  CentrixCore.SriClient.send_document(signed_xml, 1)

# 4. Verificar autorización
{:ok, %{status: "AUTORIZADO", response: auth_xml}} =
  CentrixCore.SriClient.is_authorized(key, 1)
```

Ver [`AGENTS.md § 6`](./AGENTS.md#7-the-full-electronic-invoicing-lifecycle) para el flujo completo.

## Requisitos

- Elixir `~> 1.17`
- OpenSSL instalado en el sistema (para lectura de certificados P12)
- Certificado digital válido emitido por una CA autorizada en Ecuador (BCE, Security Data, etc.)

## Sandbox Testing

Pruebas end-to-end contra el entorno de pruebas del SRI:

```bash
# Factura
TEST_P12_FILE_PASSWORD="tu_password" mix run sandbox/test_invoice.exs

# Nota de Crédito
TEST_P12_FILE_PASSWORD="tu_password" mix run sandbox/test_credit_note.exs
```

Requiere `test/fixtures/file.p12` con un certificado válido.

## Tests

```bash
mix test
```

## Estado del proyecto

Versión `0.1.0` — en desarrollo activo. La API puede cambiar antes de la v1.0.0.

## Licencia

MIT — ver [LICENSE.md](./LICENSE.md).
