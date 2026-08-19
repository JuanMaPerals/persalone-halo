# Estado verificable de gates

**Actualizado:** 2026-08-19

> La regla sigue siendo la misma: el estado se basa en gates de aceptación, no en volumen de código. `PREPARED` no equivale a `MEASURED`.

| Gate | Estado en la rama G0/G1 | Evidencia actual | Límite explícito |
|---|---|---|---|
| G0 — gobernanza automatizable | `PREPARED` | `CONTRIBUTING.md` y `SECURITY.md` corregidos; preflight versionado; workflows de verificación, secret scan y SBOM. | No confirma protección de `main`, reporte privado ni características de GitHub que requieren acción del propietario. |
| G1 — Flutter y contratos | `PREPARED` | Shell Android/iOS generado; contratos Dart versionados; análisis y pruebas locales verdes. | No hay adaptador Halo, BLE, audio, proveedor, agente ni OTA. |
| G2 — conectividad Halo | `BLOCKED` | No se ha añadido código de conexión o discovery. | Requiere versiones fijadas de firmware/SDK y ensayos físicos. |
| G3 — entrada aislada | `BLOCKED` | No hay micrófono ni transporte de captura. | Ninguna captura física está acreditada. |
| G4 — salida aislada | `BLOCKED` | No hay playback ni confirmación humana. | Ninguna salida física está acreditada. |
| G5 — conversación | `BLOCKED` | No hay STT, MT, TTS ni proveedor. | No se declara traducción audible. |
| G6 — duplex/AEC | `BLOCKED` | No hay rutas simultáneas ni ensayos. | No se declara full-duplex, barge-in o AEC. |
| G7 — agentes | `BLOCKED` | No hay runtime ni manifiestos de agentes. | No se habilitan herramientas, BLE, audio ni Lua para agentes. |
| G8 — release móvil | `BLOCKED` | No hay firma, despliegue ni flujo de tiendas. | No se publica ni se automatiza release. |

## Validación local de G1

La rama ejecutó correctamente `flutter analyze`, dos pruebas de contratos (`dart test` en `packages/contracts`) y dos pruebas de widgets (`flutter test` en `apps/mobile`). El workflow CI todavía requiere su primera ejecución en GitHub antes de poder seleccionarse como check obligatorio.

## Acciones manuales pendientes

El propietario debe completar y verificar los ajustes indicados en [GITHUB_MANUAL_SETTINGS.md](GITHUB_MANUAL_SETTINGS.md). Hasta entonces, no se afirma que `main` esté protegida ni que exista un canal privado de vulnerabilidades.

## Proximidad permitida

Tras la revisión y merge de G0/G1, el próximo trabajo debe comenzar con una decisión explícita sobre G2. No se habilitan integración BLE, audio, proveedor, agente ni OTA sin una autorización posterior.
