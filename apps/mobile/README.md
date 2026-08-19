# PersalOne Mobile

Shell Flutter mínimo para Android e iOS dentro de la base G1 de PersalOne Halo.

## Estado y límite

Este paquete es `PREPARED`. Solo verifica que el workspace, los contratos y la UI mínima compilan y se prueban. No integra Halo BLE, micrófono, altavoz, audio, STT, traducción, TTS, proveedores, agentes, Lua ni OTA.

La pantalla muestra explícitamente este límite. Una capacidad de dispositivo debe permanecer bloqueada hasta que un adaptador la declare y exista evidencia física reproducible.

## Validación local

Ejecuta desde la raíz del repositorio:

```bash
flutter pub get
flutter analyze
(cd apps/mobile && flutter test)
```

Consulta [el estado de gates](../../docs/STATUS.md) y [la auditoría de arquitectura](../../docs/ARCHITECTURE_AUDIT_2026-08-19.md) antes de ampliar el alcance.
