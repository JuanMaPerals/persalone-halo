# Contribuir a PersalOne Halo

PersalOne Halo es un runtime móvil local-first en fase temprana. La primera validación prevista es traducción bidireccional ES↔EN; el repositorio no declara aún una ruta física Halo, BLE, audio, full-duplex, AEC, proveedores, agentes ni OTA implementados.

## Límites de evidencia y privacidad

Toda contribución debe diferenciar de forma visible entre `SIMULATED`, `PREPARED`, `MEASURED`, `BLOCKED` y `FAILED`. Una simulación, un ACK de transporte o una afirmación del fabricante no justifican el estado `MEASURED`.

No incluyas credenciales, claves API, certificados, archivos `.env`, audio privado, transcripciones, perfiles de voz, identificadores de dispositivo, datos personales ni materiales propietarios de terceros. El repositorio usa Apache-2.0 exclusivamente para código propio; las licencias de SDKs, modelos, voces, datasets y activos de terceros permanecen separadas.

## Flujo local

Instala la versión de Flutter fijada por `.github/workflows/verify.yml`, después ejecuta desde la raíz:

```bash
flutter pub get
flutter analyze
(cd packages/contracts && dart test)
(cd apps/mobile && flutter test)
bash tooling/preflight.sh --all
```

El preflight rechaza rutas sensibles y detecta indicadores comunes de secretos en archivos trackeados. No sustituye una revisión humana ni un escáner de secretos gestionado.

## Reglas de cambio

Los cambios deben ser pequeños, probados y revisables. Trabaja siempre en una rama; no realices push directo a `main`. Actualiza pruebas y documentación con cualquier cambio de comportamiento o contrato. Antes de abrir un PR, ejecuta análisis estático, pruebas y preflight.

Los contratos de `packages/contracts` no pueden depender de Flutter, SDKs de dispositivos, proveedores ni secretos. Un adaptador que no declare una capacidad verificable debe bloquearla por defecto. Ningún agente o proveedor obtiene acceso a BLE, audio, Lua, OTA o credenciales por el mero hecho de estar instalado.

## Revisión y divulgación de seguridad

La configuración de protección de `main`, reporte privado de vulnerabilidades y otros ajustes de GitHub requiere acción del propietario. Consulta [los ajustes manuales pendientes](docs/GITHUB_MANUAL_SETTINGS.md) y no declares que estén activos hasta verificarlo.

No abras una incidencia pública con información sensible o un exploit reproducible. Solicita al propietario una ruta privada y sigue [SECURITY.md](SECURITY.md).
