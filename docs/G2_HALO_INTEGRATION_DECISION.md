# Decisión de integración G2 — Halo DeviceAdapter

**Estado:** `PREPARED` — investigación de solo lectura; no implementa ni valida una conexión física.

**Repositorio de producto:** `JuanMaPerals/persalone-halo`

**Alcance:** ruta Flutter para conexión, estado, identidad, batería, Lua, USERDATA, display y diagnóstico de Halo.

**Fuera de alcance:** OTA, flashing, hardware físico, captura/reproducción aceptada por una persona, proveedores de voz y cualquier afirmación `MEASURED`.

> **Veredicto:** usar el SDK Flutter oficial como transporte BLE encapsulado para discovery, conexión, reconexión, servicios, estado y la característica de audio de salida. El producto debe envolverlo detrás de un `HaloDeviceAdapter` propio y fail-closed. USERDATA, comandos Lua permitidos, metadatos de batería completos, identidad/versiones y notificaciones de audio de micrófono requieren una capa de protocolo propia y mínima. Ninguna de estas rutas puede declararse `MEASURED` hasta una validación física reproducible con Halo, firmware y dispositivos móviles fijados.

## 1. Evidencia y alcance

| ID | Afirmación | Fuente primaria | Revisión consultada | Estado | Límite |
|---|---|---|---|---|---|
| E-001 | El firmware documenta un servicio Lua, batería y transporte de audio, con UUIDs y formatos de canal definidos. | Protocolo oficial Halo [1] | `halo-firmware` `78bb15368f78ffe94b1b77b5f592ebe7a3f001a3`; consultado 2026-08-19 | **[VERIFICADO]** | No demuestra que un teléfono concreto pueda conectar ni entregar audio audible. |
| E-002 | El firmware acepta un único enlace BLE y conserva hasta cinco bonds con ventana física para un peer nuevo. | Pairing/protocolo oficial [1] [2] | Misma revisión | **[VERIFICADO]** | No prueba la experiencia de emparejamiento por versión de Android/iOS. |
| E-003 | `brilliant_ble` implementa scan, `connect`, `reconnect`, discovery de servicios, MTU/PHY Android y estado de conexión. | SDK Flutter oficial [3] [4] | `brilliant_sdk` `9a4cacf7d395195fad338bdb971b2c1ebf484180`; consultado 2026-08-19 | **[VERIFICADO]** | La cobertura del SDK no reemplaza pruebas de compatibilidad móvil. |
| E-004 | Los contratos actuales bloquean por defecto una capacidad no declarada y solo consideran usable una capacidad `MEASURED`. | `packages/contracts/lib/src/capability.dart` | `origin/main` `388f55ecbe31c582fd781dce98e25cc3c1fcb3b5` | **[VERIFICADO]** | Aún no define un puerto `DeviceAdapter`, identidad ni estados BLE. |
| E-005 | USERDATA se multiplexa con REPL usando el marcador `0x01`; el remitente es responsable de fragmentar/reensamblar USERDATA al MTU negociado. | Protocolo y firmware oficiales [1] [5] | Misma revisión | **[VERIFICADO]** | No existe aún un codec/product-contract de USERDATA en HORIZON. |
| E-006 | El firmware expone APIs Lua para batería, EUI, display, speaker, micrófono, AEC y voice mode. | Protocolo oficial Halo [1] | Misma revisión | **[VERIFICADO]** | La disponibilidad real depende de firmware, estado de emparejamiento, arbitraje y hardware. |

No se han aplicado cambios a firmware, SDK upstream, dispositivos, servicios externos ni configuraciones de GitHub durante esta investigación.

## 2. Ruta Flutter exacta propuesta

El adaptador debe depender de `brilliant_ble` **en una única capa de infraestructura**, no filtrar clases del SDK a los contratos de HORIZON. El SDK usa `flutter_blue_plus` y ya incluye los siguientes comportamientos: espera a que el adaptador BLE esté activo, consulta dispositivos conectados por el sistema, escanea los UUIDs Lua/DFU, detiene el scan antes de conectar, habilita servicios, negocia MTU/priority/PHY en Android y reusa conexiones de sistema cuando es posible.[3] [4]

```text
apps/mobile
  └─ packages/halo_adapter (propietario HORIZON)
       ├─ HaloDeviceAdapter              ← único dueño de una sesión física
       ├─ OfficialBrilliantBleTransport  ← brilliant_ble encapsulado
       ├─ HaloLuaAllowlist               ← comandos de consulta/display no destructivos
       ├─ HaloUserDataCodec              ← framing, fragmentación y reensamblaje propios
       ├─ HaloDiagnostics                ← datos estructurados y sin payload PCM
       └─ ScriptedHaloFixture            ← mismo puerto, estado SIMULATED

packages/contracts
  └─ DeviceAdapterPort / CapabilityManifest / RuntimeError
```

La primera implementación G2 debe limitarse a discovery, selección explícita de dispositivo, connect/reconnect, estado, identidad, versión, batería, manifest y diagnóstico. El adaptador no expondrá una bandera `connected` hasta que se hayan habilitado los servicios obligatorios, activado notificaciones requeridas y reunido los metadatos mínimos de sesión. Una pérdida de enlace invalida la sesión y deja todas las capacidades en `BLOCKED` o `FAILED`; nunca realiza una reconexión silenciosa que parezca continuidad de datos.

## 3. Discovery, pairing, conexión y reconexión

| Aspecto | Ruta G2 | Evidencia | Regla HORIZON |
|---|---|---|---|
| Discovery | `BrilliantBluetooth.getSystemConnectedDevices()` primero y `scan()` después, filtrando por Lua service UUID; presentar selección explícita al usuario. | El SDK consulta devices conectados por sistema antes de scan; el firmware anuncia `Halo XX` y el UUID Lua.[1] [3] | No conectar automáticamente al RSSI más alto como identidad de usuario. Persistir solo un identificador consentido y en almacenamiento seguro. |
| Pairing | Solicitar conexión y tratar el rechazo de pairing como error recuperable. | Halo admite hasta cinco bonds; un peer nuevo necesita ventana de pairing o estado out-of-box; los atributos Lua requieren enlace cifrado.[1] [5] | No abrir, activar ni simular una ventana física de pairing. La UI explica el requisito físico sin afirmar éxito. |
| Connection state | Mapear solamente estados observados del SDK/transporte a `discovering`, `connecting`, `ready`, `disconnecting`, `disconnected`, `failed`. | El SDK devuelve stream connected/disconnected y habilita servicios antes de entregar el dispositivo.[3] | `ready` exige servicio Lua + RX/TX + notificaciones. Un resultado de scan no equivale a conexión. |
| Reconnect | Reusar `BrilliantBluetooth.reconnect(uuid)` mediante una política acotada y cancelable. | El SDK soporta `reconnect`, con tratamiento de sistema conectado y auto-reconnect Android para desconexiones no iniciadas por usuario.[3] | Backoff con máximo y consentimiento de usuario; no reconectar después de `disconnect` explícito ni esconder el motivo. |
| Concurrencia | Una sesión `HaloDeviceAdapter` por dispositivo y una conexión física como máximo. | El firmware acepta una conexión a la vez.[1] | Tratar la toma por otro host/sistema como transición a `FAILED` o `BLOCKED`, no como una segunda sesión. |

## 4. Capacidades y rutas de transporte

| Área solicitada | Qué está soportado por firmware | Qué cubre el SDK Flutter | Trabajo directo de HORIZON | Evidencia física pendiente |
|---|---|---|---|---|
| Identidad y revisión | `frame.get_eui()`, hardware/firmware/git tag y secure-enclave revision se exponen por Lua.[1] | El SDK expone un `remoteId` del teléfono/BLE y envío de strings Lua, pero no un modelo Halo de identidad/versiones.[3] | Allow-list de consultas Lua, parser de respuesta tipado y política de redacción de identificadores. | Confirmar formato/respuesta en Halo con firmware fijado. |
| Batería | Servicio estándar `0x180F`: level `0x2A19` y power state `0x2A1A`; API Lua ofrece nivel, voltaje y carga.[1] [2] | No se observa una abstracción de batería en `brilliant_ble` inspeccionado.[3] | Descubrir/leer/suscribirse a batería estándar; fallback Lua solo tras evaluar privilegios y parsing. | Confirmar permisos, notificaciones y semántica de carga en dispositivo. |
| Lua REPL | Lua RX/TX full-duplex; control codes incluyen acciones destructivas y de reset.[1] | `sendString`, respuesta de texto, break/reset y carga de script están implementados.[3] | Prohibir por defecto control codes `0x02–0x07`, file APIs, carga de scripts y cualquier texto Lua arbitrario. Exponer solo builders de consultas/display aprobadas. | Confirmar timeouts, escapes y concurrencia con un loop Lua real. |
| USERDATA | RX con marcador `0x01`, anillo separado de REPL; firmware exige pairing/cifrado.[1] [5] | `sendData` añade `0x01` y espera ACK; el mensaje de alto nivel está orientado a Frame.[3] [6] | Codec propio versionado, límites de tamaño, fragmentación, reensamblaje, timeout, backpressure y pruebas adversariales. | Confirmar framing intermedio y recepción real de la aplicación Lua de Halo. |
| MTU y fragmentación | MTU cambia por evento; USERDATA exige fragment/reassembly del usuario.[1] [2] | Calcula longitudes desde `device.mtuNow`, habilita long writes y fragmenta mensajes de alto nivel; aplica ajuste extra para Halo audio.[3] | Recalcular presupuesto por MTU observada, no por `512` documentado; rechazar fragmentos inconsistentes y registrar sólo metadatos. | Medir MTU efectiva por Android/iOS y throughput sin pérdida. |
| Display | Lua ofrece texto, bitmaps, color, brillo, geometría y consultas de tamaño.[1] | `clearDisplay()` y `sendString()`; no se observa un puerto typed de display Halo.[3] | `DisplayPort` con comandos de alto nivel allow-listed, tamaño máximo y encoding seguro. | Validar visibilidad, legibilidad, brillo y confirmación humana. |
| Speaker / output | AUDIO RX y APIs `speaker.start/play/stop`; PCM o LC3.[1] | `sendAudio` usa la característica de salida a Halo y exige el canal descubierto.[3] | **No en G2:** reservar un `HaloAudioPort` sin habilitar playback. | G4: audio audible, formato, underruns y latencia. |
| Microphone / input | AUDIO TX y `microphone.start/read/status`; PCM/LC3; estados `stopped`, `streaming`, `le_audio`.[1] [2] | No se observa binding de Audio TX ni puerto de micrófono Halo en `brilliant_ble`; `RxAudio` recibe mensajes de datos con framing de Frame.[3] [6] | **No en G2:** diseñar sólo el puerto; requiere suscripción a Audio TX o loop Lua/USERDATA versionado. | G3: captura real, primera muestra, pérdidas y formato. |
| AEC / voice | AEC y voice-band están disponibles por Lua, desactivados por defecto; LE Audio puede preemptar micrófono Lua.[1] | No se observa control dedicado de AEC/voice en SDK Flutter. | **No en G2:** un futuro comando allow-listed solo tras G3/G4 y pruebas G6. | G6: doble habla, echo, interrupción y ensayos de duración. |
| OTA | Servicio SMP existe en firmware.[1] | SDK contiene tipos DFU, pero no es parte de esta decisión.[4] | Prohibido: no incluirlo en dependencias, UI, puertos ni manifiesto G2. | Requiere autorización humana distinta; fuera de alcance. |

## 5. Decisiones de arquitectura para implementar después de esta investigación

| Decisión | Estado | Justificación y límite |
|---|---|---|
| Encapsular `brilliant_ble` | **[DECISIÓN PREPARADA]** | Evita duplicar discovery, conexión y negociación que el SDK ya implementa, sin convertir su API en el dominio de HORIZON. |
| Crear `DeviceAdapterPort` y `HaloDeviceAdapter` propios | **[DECISIÓN PREPARADA]** | El contrato actual solo declara capacidades; faltan estados de sesión, identidad, diagnóstico, lifecycle y transporte fail-closed. |
| Añadir `ScriptedHaloFixture` con el mismo puerto | **[DECISIÓN PREPARADA]** | Cumple la regla de simulación contractual: un fixture puede ser `SIMULATED`, nunca `MEASURED`. |
| Habilitar Lua arbitrario, carga de scripts o control codes | **[BLOQUEADO]** | El firmware expone reboot/reset/remove y operaciones de archivo; esos privilegios no son necesarios para G2.[1] [2] |
| Habilitar audio Halo, AEC, voice o LE Audio | **[BLOQUEADO]** | Son gates G3–G6 y el firmware documenta arbitraje/preemption; no existe evidencia móvil de HORIZON todavía.[1] [2] |
| Exponer OTA | **[BLOQUEADO]** | Está prohibido por el alcance y requiere autorización humana/validación separada. |

El contrato G2 debe incorporar los tipos `DeviceConnectionState`, `DeviceIdentity`, `BatterySnapshot`, `AdapterDiagnostic`, `DeviceAdapterPort`, `LuaTransportPort` y `UserDataTransportPort`. Cada objeto debe incluir `schemaVersion`, `adapterId`, `sourceRevision`, `truthLabel`, timestamp monotónico y causa/diagnóstico cuando no esté listo. La capacidad debe seguir bloqueada hasta que exista evidencia `MEASURED`; por ello `CapabilityState.isUsable` no se relajará.

## 6. Riesgos y controles fail-closed

| Riesgo | Control obligatorio |
|---|---|
| Comando Lua destructivo o no revisado | Allow-list compilada; no exponer métodos `sendString`, `uploadScript`, reset, remove, reboot ni file API fuera de infraestructura. |
| Datos de USERDATA fragmentados o mezclados con REPL | Codec con esquema, longitud, correlación, checksum/validación, timeout, tamaño máximo y pruebas de fragmentos fuera de orden. |
| Estado conectado falso | Emitir `ready` sólo después de descubrir servicio/characteristics, activar notifications y completar el inventario mínimo. |
| Identificadores o respuestas sensibles en logs | Diagnostics estructurados con hashes/longitudes/códigos; no registrar EUI, payloads Lua, USERDATA, PCM o transcript por defecto. |
| Pérdida o takeover de conexión | Invalidar sesión y emitir fallo tipado; no reutilizar audio, permisos ni `streamEpoch` de la sesión previa. |
| Confusión de simulación con dispositivo | El fixture usa `adapterId=scripted-halo-fixture` y truth label `SIMULATED`; no imita EUI, batería o RSSI físicos. |
| Inestabilidad de upstream | Fijar los SHAs de firmware y SDK aquí documentados y actualizar mediante una nueva decisión/revisión, no flotando en `main`. |

## 7. Validación física necesaria antes de G2 `MEASURED`

| Ensayo | Evidencia mínima | Estado actual |
|---|---|---|
| Discovery | Nombre, UUID anunciado, OS, firmware/SDK SHA, y selección explícita registrada sin EUI bruto. | **[PENDIENTE DE INVENTARIO REAL]** |
| Pairing y conexión | Ventana de pairing, resultado cifrado, discovery de servicios y activación de notificaciones. | **[PENDIENTE DE INVENTARIO REAL]** |
| Reconexión | 20 ciclos con separación entre disconnect explícito, pérdida de enlace y reconnect de sistema. | **[PENDIENTE DE INVENTARIO REAL]** |
| Batería | Lectura/notificación y contraste con estado de carga observado. | **[PENDIENTE DE INVENTARIO REAL]** |
| Identidad/versiones | Respuesta allow-listed y redacción segura en diagnóstico. | **[PENDIENTE DE INVENTARIO REAL]** |
| Display | Clear/texto de prueba, confirmación humana de visibilidad y captura de evidencia consentida. | **[PENDIENTE DE INVENTARIO REAL]** |
| USERDATA | Fragmentación/reassembly al MTU real, timeout, backpressure y fallo seguro. | **[PENDIENTE DE INVENTARIO REAL]** |

## 8. Siguiente acción segura

La siguiente PR de implementación puede crear exclusivamente los contratos G2, `HaloDeviceAdapter`, adaptador `brilliant_ble`, fixture determinista, pruebas unitarias y diagnósticos redacted. Debe fijar las revisiones upstream anteriores, mantener OTA/audio/AEC/voice bloqueados y no intentar conectar a un dispositivo físico sin el inventario y consentimiento apropiados.

## Referencias

[1]: https://github.com/brilliantlabsAR/halo-firmware/blob/78bb15368f78ffe94b1b77b5f592ebe7a3f001a3/applications/halo/PROTOCOL.md "Halo protocol — firmware oficial, revisión fijada"
[2]: https://github.com/brilliantlabsAR/halo-firmware/blob/78bb15368f78ffe94b1b77b5f592ebe7a3f001a3/applications/halo/BLE_SERVICES.md "Halo BLE services — firmware oficial, revisión fijada"
[3]: https://github.com/brilliantlabsAR/brilliant_sdk/blob/9a4cacf7d395195fad338bdb971b2c1ebf484180/flutter/packages/brilliant_ble/lib/brilliant_bluetooth.dart "BrilliantBluetooth — SDK Flutter oficial, revisión fijada"
[4]: https://github.com/brilliantlabsAR/brilliant_sdk/blob/9a4cacf7d395195fad338bdb971b2c1ebf484180/flutter/packages/brilliant_ble/lib/brilliant_device.dart "BrilliantDevice — SDK Flutter oficial, revisión fijada"
[5]: https://github.com/brilliantlabsAR/halo-firmware/blob/78bb15368f78ffe94b1b77b5f592ebe7a3f001a3/modules/halo/src/ble_lua.c "BLE Lua implementation — firmware oficial, revisión fijada"
[6]: https://github.com/brilliantlabsAR/brilliant_sdk/blob/9a4cacf7d395195fad338bdb971b2c1ebf484180/flutter/packages/brilliant_msg/lib/rx/audio.dart "RxAudio — SDK Flutter oficial, revisión fijada"
