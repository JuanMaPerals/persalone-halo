# Auditoría de arquitectura — PersalOne Halo

**Fecha:** 2026-08-19

**Repositorio auditado:** `JuanMaPerals/persalone-halo`

**Commit auditado:** `6ce06dd118e066c0b568cc76aa2e9c6438ff6261` (`main`)
**Estado:** **PRE-IMPLEMENTACIÓN — no autoriza cambios estructurales todavía**

> **Veredicto:** el repositorio es una base documental válida y limpia para comenzar, pero no contiene aún una aplicación Flutter, contratos ejecutables, dependencias, CI, tests ni adaptador Halo. Por tanto, no es posible afirmar que exista una implementación auditable de traducción, BLE, audio o agentes. El siguiente hito debe ser un baseline ejecutable y mínimo, no una integración de audio ni una interfaz simulada.

Esta auditoría no modifica firmware, SDK upstream, infraestructura, secretos ni código de producto. El único cambio local es este informe de auditoría dentro del repositorio autorizado.

## 1. Evidencia consultada

| ID | Hallazgo | Fuente | Estado | Límite |
|---|---|---|---|---|
| E-01 | El árbol Git está limpio, en `main`, con dos commits y sin archivos de código, manifiestos de dependencias ni workflows. | `git status`, `git fsck`, `git ls-files`; commit auditado | **[VERIFICADO]** | No demuestra que el código descrito fuera del repositorio esté disponible o sea reutilizable. |
| E-02 | La arquitectura actual declara un runtime local-first, evidencia censurada, adaptadores de dispositivo y una política fail-closed. | `README.md`; `docs/PERSALONE_RUNTIME_MASTER_ARCHITECTURE.md` | **[VERIFICADO]** | Son decisiones documentadas, no comportamiento ejecutable. |
| E-03 | El repositorio declara que no hay evidencia física de Halo, audio, full-duplex, AEC, latencia o batería. | `README.md`; `docs/STATUS.md` | **[VERIFICADO]** | Correcto como límite, pero requiere que la UI futura no sugiera lo contrario. |
| E-04 | La rama `main` no tiene protección; no hay workflows de GitHub Actions; el endpoint de reporte privado de vulnerabilidades respondió 404. | GitHub API de solo lectura, 2026-08-19 | **[VERIFICADO]** | Un 404 no distingue entre función deshabilitada, no disponible o autorización insuficiente; se trata como gate no satisfecho. |
| E-05 | `CONTRIBUTING.md` contradice el árbol: habla de ausencia de licencia, `.node-version`, `package.json`, comandos npm y una guía que no existen; sí existe `LICENSE` Apache-2.0. | `CONTRIBUTING.md`; árbol auditado | **[VERIFICADO]** | No prueba intención; sí bloquea onboarding y reproducibilidad. |
| E-06 | Halo usa un único enlace BLE, admite hasta cinco bonds con ventana de pairing y expone un canal Lua seguro, batería, OTA y rutas de audio específicas. | Firmware y documentación oficial Halo [1] [2] [3] | **[VERIFICADO]** | Debe fijarse un commit/versión de firmware para cada ensayo físico. |
| E-07 | El SDK Flutter oficial ofrece `brilliant_ble` y `brilliant_msg`; cubre conexión, MTU, reconexión y salida de audio a Halo, pero su superficie de pruebas visible es muy reducida y su adaptador no debe convertirse en dominio de producto. | SDK y documentación oficial [4] [5] [6] | **[VERIFICADO]** | No demuestra que la ruta satisfaga latencia, compatibilidad de todos los móviles o full-duplex. |

## 2. Riesgos arquitectónicos priorizados

| Prioridad | Riesgo | Impacto | Decisión / gate requerido |
|---|---|---|---|
| **P0** | No existe código ni contrato ejecutable en el repositorio. | No hay build, test, SBOM, análisis ni compatibilidad Android/iOS que auditar. | Crear primero un workspace Flutter mínimo y un contrato canónico; no iniciar BLE/audio antes de que compile y tenga CI. |
| **P0** | `main` no está protegida y no hay CI ni canal privado de vulnerabilidades verificable. | Un cambio futuro podría llegar sin revisión, pruebas o ruta segura de divulgación. | Activar protección de rama, revisión obligatoria cuando haya colaborador, checks requeridos, escaneo de secretos/SBOM y reporte privado antes de aceptar contribuciones externas. |
| **P0** | La documentación de contribución no coincide con el repositorio real. | Onboarding, CI y claims de licencia pueden ser erróneos. | Corregir `CONTRIBUTING.md`, declarar el stack real y eliminar referencias a archivos/comandos inexistentes. |
| **P1** | El firmware permite comandos Lua de alto privilegio, incluidos reboot, reset del runtime y borrado de archivos. | Un agente, proveedor o entrada no confiable no debe alcanzar el REPL ni los códigos de control. | Crear una allow-list de comandos y prohibir por diseño Lua arbitrario, `CTRL+B..G`, gestión de archivos y OTA en el runtime del traductor. |
| **P1** | El firmware tiene un único propietario de micrófono/altavoz; LE Audio puede preemptar la ruta Lua. | Dos propietarios o una transición implícita causarán fallos, audio perdido o falsas métricas de duplex. | `HaloSession` será el único dueño del transporte; elegir una ruta de audio por sesión y modelar explícitamente la preemption. |
| **P1** | El audio de micrófono no llega por una característica dedicada en la ruta Lua: usa `LUA RX` desde un loop Lua; el audio de salida usa `AUDIO TX` dedicado. | El MVP necesita un loop Lua mínimo y un demultiplexado/flujo de entrada robusto, no solo llamadas de SDK. | Validar captura aislada y playback aislado antes de STT/TTS; instrumentar pérdidas, discontinuidades y backpressure. |
| **P1** | AEC y modo de voz existen en firmware, pero son opt-in y no constituyen una garantía de experiencia. | Activar AEC sin medición puede ocultar doble habla o degradar STT. | AEC/voice mode tras una prueba de ruta de referencia, ruido y doble habla; permanecer `BLOCKED` hasta entonces. |
| **P1** | Los proveedores cloud requieren una frontera de credenciales y consentimiento; el cliente móvil no puede contener claves de servidor. | Exposición de claves y envío silencioso de audio/transcripciones. | Usar tokens efímeros emitidos por un backend mínimo solo si el proveedor lo exige; si no, BYOK guardado en almacenamiento seguro y visible al usuario. |
| **P2** | Las políticas de tiendas requieren permisos y declaraciones exactas de Bluetooth, micrófono y datos. | Rechazo de publicación o prácticas de privacidad inconsistentes. | Matriz de permisos y Data Safety/App Privacy derivada del comportamiento real, no de intenciones.[7] [8] [9] |

## 3. Hallazgos de Halo que cambian el diseño

Halo acepta una sola conexión BLE a la vez. El vínculo debe estar cifrado y el emparejamiento de un dispositivo nuevo depende de la ventana física de pairing; el firmware conserva hasta cinco bonds con reemplazo LRU.[1] [2] El adaptador móvil no debe escoger «el dispositivo más cercano» como identidad definitiva: debe presentar explícitamente el dispositivo previamente consentido y tratar la toma del enlace por otro host como estado recuperable.

La ruta de menor riesgo para el primer MVP es la **ruta BLE Lua personalizada**, no LE Audio como ruta primaria. El SDK Flutter oficial ya negocia MTU, descubre el servicio, gestiona reconexión y expone una característica de salida de audio para Halo.[4] [5] En firmware, el audio de salida llega por la característica dedicada `AUDIO TX`, mientras que el micrófono se captura mediante `frame.microphone` y se reenvía desde el loop Lua sobre `LUA RX`; el SDK de mensajes incluye un receptor de streaming para este patrón.[2] [5] Esto permite una primera vertical completa con SDK oficial encapsulado, pero obliga a tratar el loop Lua enviado a Halo como un artefacto versionado, mínimo y estrictamente permitido.

El firmware también implementa LE Audio estándar y arbitraje exclusivo de micrófono/altavoz. Una sesión LE Audio puede preemptar la ruta Lua y el uso de LE Audio desde una aplicación móvil no queda demostrado por el SDK Flutter inspeccionado.[1] [3] Por ello, LE Audio será una **opción de optimización reversible** posterior a la medición de compatibilidad por versión de iOS/Android, no una dependencia del MVP.

## 4. Arquitectura objetivo propuesta

La propuesta conserva el principio local-first ya documentado y sustituye la ambigüedad actual entre runtime de PC, Python, TypeScript y simuladores por un único producto móvil Flutter. No se introducirá un backend persistente en la ruta de audio. La aplicación es la dueña de sesión y orquestación; Halo es periférico de entrada/salida; los proveedores y agentes son adaptadores opcionales.

```text
Halo (BLE seguro; Lua/audio/display)          Android / iOS
                │                                  │
                └── HaloSdkAdapter ──────────> HaloSession
                                                   │
                                          ConversationOrchestrator
                         ┌─────────────────────────┼─────────────────────────┐
                         │                         │                         │
                  AudioPipeline             ProviderRouter           PolicyEvidence
               VAD · segmentación         STT · MT · TTS           consentimiento · purga
                         │                         │                         │
                         └────────────── AgentRuntime (opcional) ────────────┘
                                        manifest · permisos · revocación
```

| Límite | Responsabilidad | Regla |
|---|---|---|
| `apps/mobile` | Flutter UI, permiso, sesión, transcript, estados y accesibilidad. | No accede directamente a características BLE, proveedores ni secretos. |
| `packages/contracts` | Modelos, errores, eventos, estados de evidencia, `CapabilityManifest` y schemas. | Dart puro; fuente de verdad única y versionada. |
| `packages/halo_adapter` | SDK oficial, discovery, pairing, reconexión, batería, display, Lua allow-list, audio y diagnóstico. | Un solo `HaloSession` por dispositivo; sin comandos destructivos ni OTA. |
| `packages/conversation_runtime` | VAD, segmentación, epochs, cancelación, barge-in, historial efímero y presupuesto de latencia. | No conoce proveedor concreto ni Flutter. |
| `packages/provider_contracts` | Puertos STT/MT/TTS/realtime y pruebas de conformidad. | Un proveedor no puede alterar estados de sesión o privacidad. |
| `packages/agent_runtime` | Agentes instalables, manifiesto, permisos, aislamiento lógico y registro de decisiones. | No participa en traducción de MVP y no tiene permiso BLE/audio/Lua por defecto. |
| `packages/policy_evidence` | Consentimiento, almacenamiento seguro, redacción, retención, métricas y exportación censurada. | Nunca registra PCM, transcript bruto, credenciales ni identificadores físicos por defecto. |
| `packages/platform_bridge` | Kotlin/Swift exclusivamente para APIs que Flutter/SDK no cubran de forma demostrable. | Puentes pequeños, tipados y sin lógica de producto. |

## 5. Interfaces y contratos mínimos

| Contrato | Responsabilidad | Reglas no negociables |
|---|---|---|
| `HaloConnectionPort` | Descubrimiento, selección consentida, conexión, identidad, batería, MTU y reconexión. | Emite transición tipada; no reconnect infinito; una conexión física por sesión. |
| `HaloCapabilityPort` | Capacidades negociadas de display, capture, playback, AEC, voice mode y estado Lua. | Solo devuelve capacidades verificadas del dispositivo/firmware actual. |
| `HaloAudioPort` | `Stream<AudioFrame>` de entrada y `Future<void>` de salida. | `AudioFrame` incluye `sessionId`, `streamEpoch`, secuencia, timestamps monotónicas, formato, discontinuidad y payload fuera de logs. |
| `ConversationOrchestrator` | Dirección EN→ES/ES→EN, PTT, mute, segmentación, barge-in, cancelación e historial local. | Incrementa `streamEpoch` ante interrupción; todo resultado tardío se descarta. |
| `SpeechToTextProvider` | Parciales, finales, timestamps, idioma, cancelación y error. | No persiste audio ni texto salvo política/consentimiento explícito. |
| `TranslationProvider` | Traducción por segmento, contexto limitado y cancelación. | No bloquea captura; siempre informa procedencia y coste medible. |
| `TextToSpeechProvider` | Flujo/primer audio, cancelación, voz y error. | La reproducción debe detenerse al barge-in antes de aceptar nuevo turno. |
| `RealtimeVoiceProvider` | Ruta speech-to-speech opcional. | No sustituye la trazabilidad de transcript, consentimientos y métricas. |
| `AgentRuntimePort` | Instalación, verificación, permisos y revocación de agentes. | Los permisos son declarativos, mínimos y aprobados por persona. |

El contrato de sesión debe llevar `sessionId`, `utteranceId`, `segmentId`, `streamEpoch`, `traceId`, dirección, política vigente y timestamps monotónicas. El epoch resuelve la condición de carrera crítica: si el usuario interrumpe durante TTS, no se podrá reproducir la salida de una frase anterior aunque el proveedor la complete tarde.

## 6. Decisiones que se deben congelar ahora

| Decisión | Motivo |
|---|---|
| Flutter para Android+iOS, con Dart como núcleo de dominio y contratos. | Cumple el alcance y mantiene una UI común sin asumir que BLE/audio debe ser enteramente Dart. |
| SDK oficial encapsulado detrás de `HaloSdkAdapter`. | Reutiliza la lógica de conexión y MTU sin acoplar el producto a sus APIs o ciclos de release. |
| Una sola ruta de audio por sesión; BLE Lua personalizada como referencia inicial. | Respeta el arbitraje de firmware y permite validar audio sin depender de soporte LE Audio de cada móvil. |
| Una sola máquina de estados de conversación y un único dueño de conexión. | Evita carreras de reconnect, Lua, capture, playback y agentes. |
| Traducción independiente de agentes. | La función crítica no debe depender de memoria, herramientas o LLMs. |
| Privacidad local-first, buffers efímeros y telemetría censurada por defecto. | Audio, transcript y voz son datos sensibles; el envío remoto debe ser explícito y observable. |
| Estados de evidencia `SIMULATED`, `PREPARED`, `MEASURED`, `BLOCKED`, `FAILED`. | Evita que UI, demo o ACK de transporte se presenten como validación física. |

## 7. Decisiones que deben permanecer reversibles

| Decisión | Mecanismo de reversibilidad |
|---|---|
| Proveedor STT, MT, TTS o speech-to-speech. | Puertos de proveedor, suite de conformidad y matriz de coste/calidad/latencia. |
| Local, cloud o híbrido. | Política por sesión; no usar datos de proveedor en tipos de dominio. Apple ofrece análisis de voz local con APIs modernas en sistemas compatibles y ML Kit puede traducir texto en dispositivo, pero ambas rutas exigen evaluación de hardware, idiomas y calidad.[10] [11] |
| BLE Lua frente a LE Audio. | `HaloAudioPort` común; un adaptador de ruta por sesión, no condicionales en UI/orquestador. |
| Backend para tokens efímeros o BYOK local. | `CredentialPolicy` y `TokenBrokerPort`; no insertar claves en la app. |
| Modelo de distribución de agentes. | `AgentManifest` versionado, verificación de integridad, feature flag y permisos revocables. |
| Retención de historial. | Política por usuario/región que, por defecto, no persiste conversación. |

## 8. Gates de seguridad y de calidad

| Gate | Evidencia de salida | Estado actual |
|---|---|---|
| G0 — Higiene de repositorio | `CONTRIBUTING` coherente, licencia confirmada, protección de `main`, CI, private reporting y escaneo de secretos. | **BLOCKED** |
| G1 — Contrato canónico | Schemas Dart, pruebas unitarias y fixture que comparten tipos/errores con la app. | **BLOCKED** |
| G2 — Conectividad Halo | Dispositivo/firmware/SDK fijados; pairing, reconexión, identidad, batería, MTU y display reproducibles. | **BLOCKED** |
| G3 — Entrada aislada | 30 minutos de captura, discontinuidades, formato y fuga de buffer medidos. | **BLOCKED** |
| G4 — Salida aislada | 30 minutos de playback y confirmación humana de escucha, no solo ACK. | **BLOCKED** |
| G5 — Conversación | STT→MT→TTS con parciales, cancelación, PTT/mute, pérdida de red y transcript local. | **BLOCKED** |
| G6 — Duplex/AEC | 30 minutos simultáneos, doble habla, pérdidas, reconexiones y evidencia humana. | **BLOCKED** |
| G7 — Agentes | Manifest, integridad, permisos, revocación, auditoría y pruebas de prompt/tool injection. | **BLOCKED** |
| G8 — Release móvil | Permisos reales, política de privacidad, Data Safety/App Privacy, SBOM, licencias y tests por plataforma. | **BLOCKED** |

## 9. Orden exacto de ejecución

1. Corregir gobernanza del repositorio: `CONTRIBUTING.md`, protección de rama, CI, escaneo de secretos, SBOM y ruta privada de vulnerabilidades. No se integra audio en paralelo.
2. Crear el workspace Flutter mínimo con `apps/mobile`, `packages/contracts`, análisis estático, tests y una pantalla de estado sin métricas ficticias.
3. Definir y probar el contrato común de sesión, frame, capacidad, evidencia y error; crear un `ScriptedHaloFixture` que implemente el mismo contrato.
4. Añadir `HaloSdkAdapter` contra versiones fijadas del SDK y firmware, comenzando por discovery, pairing, conexión, reconnect, batería, MTU, display y diagnóstico.
5. Validar audio de entrada aislada con un loop Lua mínimo allow-listed; después validar salida aislada por `AUDIO TX`. Registrar formato, pérdidas, timestamps y evidencia humana.
6. Implementar el `ConversationOrchestrator` y el pipeline EN↔ES con PTT, mute, cambio de dirección, transcript local, VAD/segmentación y cancelación. Usar un único proveedor de referencia sin codificarlo en UI.
7. Medir la matriz de proveedores: calidad, primer parcial, primer audio, coste, privacidad, red y degradación. OpenAI, Google, Azure y DeepL tienen modelos de costes y capacidades distintos; DeepL se mantiene en la capa de traducción, no como sustituto de STT/TTS.[12] [13] [14] [15] [16]
8. Habilitar barge-in y después AEC/voice mode solo si los ensayos demuestran mejora. Realizar 20 reconexiones y ensayos de 1, 4 y 8 horas antes de declarar cualquier estado `MEASURED`.
9. Incorporar agentes instalables como feature flag posterior: manifests, permisos, aislamiento, herramientas aprobadas y pruebas adversariales. Un agente no obtiene control directo de Lua, OTA, micrófono, BLE ni proveedor.
10. Preparar release candidate Android/iOS con evidencia reproducible, declaraciones de privacidad basadas en tráfico real y revisión de tiendas. No publicar automáticamente.

## 10. Límites y siguiente acción

La auditoría confirma que la documentación existente ha sido prudente al no afirmar capacidades físicas. También demuestra que el mayor riesgo actual no es la elección de modelo de IA: es empezar por integración compleja antes de tener un repositorio ejecutable, un contrato único y controles de entrega.

> **Siguiente acción recomendada:** aprobar el cierre de G0 y el contrato canónico como primer cambio. Una vez aprobados, se creará un workspace Flutter mínimo, con CI y tests verdes, dentro de `JuanMaPerals/persalone-halo`; no se tocarán los upstream ni se ejecutará OTA, Lua arbitrario o publicación.

## Referencias

[1]: https://github.com/brilliantlabsAR/halo-firmware/blob/main/PAIRING.md "Halo pairing & bonding design — firmware oficial"
[2]: https://docs.brilliant.xyz/halo/halo-sdk-bluetooth-specs/ "Talking to Halo Over Bluetooth — documentación oficial"
[3]: https://github.com/brilliantlabsAR/halo-firmware/blob/main/modules/halo/src/lua_microphone.c "lua_microphone.c — firmware oficial"
[4]: https://docs.brilliant.xyz/halo/halo-sdk-flutter/ "Brilliant SDK para Flutter — documentación oficial"
[5]: https://github.com/brilliantlabsAR/brilliant_sdk/blob/main/flutter/packages/brilliant_ble/lib/brilliant_bluetooth.dart "brilliant_bluetooth.dart — SDK oficial"
[6]: https://github.com/brilliantlabsAR/brilliant_sdk/blob/main/flutter/packages/brilliant_ble/lib/brilliant_device.dart "brilliant_device.dart — SDK oficial"
[7]: https://developer.apple.com/documentation/bundleresources/protected-resources "Protected resources — Apple Developer"
[8]: https://developer.android.com/develop/connectivity/bluetooth/bt-permissions "Bluetooth permissions — Android Developers"
[9]: https://support.google.com/googleplay/android-developer/answer/10787469?hl=en "Provide information for Google Play's Data safety section"
[10]: https://developer.apple.com/documentation/speech/speechanalyzer "SpeechAnalyzer — Apple Developer"
[11]: https://developers.google.com/ml-kit/language/translation "ML Kit Translation — Google for Developers"
[12]: https://developers.openai.com/api/docs/models/gpt-realtime "GPT-Realtime — OpenAI API"
[13]: https://cloud.google.com/speech-to-text/pricing "Speech-to-Text pricing — Google Cloud"
[14]: https://cloud.google.com/text-to-speech/pricing "Text-to-Speech pricing — Google Cloud"
[15]: https://azure.microsoft.com/en-us/pricing/details/speech/ "Azure Speech pricing — Microsoft Azure"
[16]: https://developers.deepl.com/api-reference/translate/request-translation "Translate text — DeepL API"
