# G3/G4 — Validación de audio host Android

**Estado del documento:** `PREPARED`
**Objetivo:** validar la primera ruta física de audio de HORIZON: micrófono Android → PCM local → altavoz Android.
**No valida:** Halo, Bluetooth, STT, traducción, TTS, agentes, proveedores, servicio de fondo ni OTA.

> Esta prueba no admite fixtures, PCM pregrabado ni latencias sintetizadas como criterio de aceptación. Sólo una instalación ejecutada en un dispositivo Android físico, con datos de ensayo registrados, puede producir evidencia `MEASURED`.

## 1. Implementación que se somete a ensayo

| Área | Implementación | Datos admitidos | Etiqueta antes del ensayo |
|---|---|---|---|
| G3 entrada | `AndroidMicrophoneAdapter` → canal Android → `AudioRecord` | PCM signed 16-bit, mono, 16 kHz; timestamps y diagnósticos redactados | `PREPARED` |
| G4 salida | `AndroidSpeakerAdapter` → canal Android → `AudioTrack` streaming | PCM signed 16-bit, mono, 16 kHz; writes, underruns y timestamps redactados | `PREPARED` |
| Fixture | No aplica a la ruta de aceptación | Sólo pruebas unitarias de contratos | `SIMULATED` |
| Halo micrófono/altavoz | `PreparedHaloMicrophoneAdapter` / `PreparedHaloSpeakerAdapter` | Ningún frame físico | `PREPARED/BLOCKED` |

Android exige declarar `RECORD_AUDIO` y obtener su concesión en runtime para capturar audio; además, su propia documentación advierte que el emulador no sirve para verificar captura.[1] `AudioRecord` expone una captura por pull y requiere que el lector consuma el buffer a tiempo; `AudioTrack` streaming acepta PCM por push y sus writes son la frontera de backpressure.[2] [3]

## 2. Preparación del dispositivo

| Paso | Acción | Resultado que se debe registrar |
|---|---|---|
| 1 | Usar un teléfono Android físico, con batería suficiente y sin llamada/recorder concurrente. | Modelo, fabricante, versión Android, build y ruta de salida seleccionada. |
| 2 | Instalar la APK de la rama G3/G4 y abrirla en primer plano. | SHA de commit, nombre de rama y hash de APK. |
| 3 | Pulsar **Solicitar micrófono** y conceder el permiso visible del sistema. | Concedido/denegado y marca horaria monotónica de la aplicación. |
| 4 | Desconectar auriculares Bluetooth o cableados para el ensayo inicial, salvo que se mida deliberadamente esa ruta. | `speaker` interno u otra ruta identificada. |
| 5 | No grabar ni exportar PCM, transcript, identificador de dispositivo o voz humana como evidencia. | Sólo contadores, formato, timestamps y resultado humano. |

## 3. Ensayo G3 — entrada real

1. Pulsar **Iniciar captura real**.
2. Hablar una frase corta, por ejemplo: “Prueba de PersalOne, uno dos tres”. No reutilizar un clip previamente almacenado.
3. Mantener la captura entre 5 y 10 segundos y pulsar **Detener captura**.
4. Registrar el número de frames, drops, formato efectivo, buffer, chunk, eventos de timestamp y cualquier error de `AudioRecord`.
5. Repetir tres veces en la misma ruta de audio.

`AudioRecord.getTimestamp()` asocia una posición de frame con una hora estimada de captura en un timebase monotónico cuando el sistema la ofrece.[2] Un timestamp de sistema no prueba inteligibilidad humana ni sustituye una medición de extremo a extremo.

| Criterio G3 | Aprobado únicamente si | Falla si |
|---|---|---|
| Permiso | El permiso runtime se concede explícitamente. | Se intenta capturar sin permiso o el sistema lo deniega. |
| PCM | Hay frames no vacíos, alineados con 16-bit mono. | No hay frames válidos, se recibe error o los bytes no están alineados. |
| Buffering | Los contadores de drop se registran, incluso si son cero. | Se omiten drops o se ocultan errores de read. |
| Timestamps | Se registra disponible/no disponible y su frame position cuando exista. | Se inventa una latencia a partir de un valor no medido. |

## 4. Ensayo G4 — salida real y verificación humana

1. Usar únicamente la muestra PCM obtenida en el ensayo G3 actual, conservada en memoria de forma acotada por la aplicación.
2. Pulsar **Reproducir muestra real** una sola vez por ensayo.
3. La persona presente confirma si oye la frase; no debe inferirse audibilidad de un ACK de write.
4. Registrar writes, writes parciales, underruns, ruta de salida y timestamps `AudioTrack` disponibles.
5. Repetir tres veces y anotar cualquier distorsión, silencio, ruta inesperada o interrupción.

`AudioTrack` informa de underruns del buffer de escritura y puede proporcionar un timestamp de presentación; éste es una estimación de sistema sobre la posición de frame, no una confirmación humana de que el sonido se oyó.[3] [4]

| Criterio G4 | Aprobado únicamente si | Falla si |
|---|---|---|
| Playback | El `AudioTrack` acepta la muestra actual y no reporta error. | El track no inicia, el write falla o la ruta cambia sin registro. |
| Backpressure | Los writes parciales y los underruns se registran. | Se descartan sin diagnóstico o se marca éxito pese a error. |
| Audibilidad | Una persona confirma oír la muestra actual en el altavoz/ruta declarada. | No hay confirmación humana, hay silencio o la frase no es reconocible. |
| Evidencia | Modelo, OS, commit, ruta, tres repeticiones y métricas se adjuntan a un issue privado/censurado. | Faltan datos de procedencia o se adjunta PCM/voz. |

## 5. Cálculo y etiquetado de latencia

| Métrica | Fuente permitida | Qué representa | Qué no representa |
|---|---|---|---|
| Timestamp de entrada | `AudioRecord.getTimestamp()` | Tiempo estimado de captura y posición de frame. | Latencia del usuario a la traducción. |
| Timestamp de salida | `AudioTrack.getTimestamp()` | Tiempo estimado de presentación/compromiso de un frame según el sistema. | Audibilidad confirmada o latencia de conversación completa. |
| Duración de write | Hora monotónica antes/después de `AudioTrack.write`. | Backpressure del lado aplicación. | Tiempo acústico hasta el oído. |
| Verificación humana | Registro explícito del ensayo actual. | Confirmación de que la muestra se oyó. | Una cifra de latencia precisa sin método de loopback. |

La clase `AudioTimestamp` declara expresamente que utiliza una estimación de mejor esfuerzo y no puede contabilizar demoras desconocidas por la implementación.[4] Por eso, las mediciones G3/G4 no se promocionan a una latencia de conversación ni se convierten en un número de marketing.

## 6. Registro mínimo de evidencia

```text
commit_sha:
branch:
apk_sha256:
android_model:
android_version:
audio_route:
format: pcm_s16le/16000/mono
run_number: 1|2|3
permission: granted|denied
input_frames:
input_drops:
input_timestamp: available|unavailable
output_writes:
output_partial_writes:
output_underruns:
output_timestamp: available|unavailable
human_audible: yes|no
anomalies:
truth_label: MEASURED|FAILED|BLOCKED
```

Sólo la combinación de los tres ensayos reproducibles, su procedencia y una revisión humana permite cambiar los adaptadores Android de `PREPARED` a `MEASURED`. La falta de dispositivo Android, SDK Android, permiso o evidencia deja el estado en `PREPARED` o `BLOCKED`; no se emplea una degradación silenciosa.

## Referencias

[1]: https://developer.android.com/media/platform/mediarecorder "Android Developers — Media Recorder overview"
[2]: https://developer.android.com/reference/android/media/AudioRecord "Android Developers — AudioRecord"
[3]: https://developer.android.com/reference/android/media/AudioTrack "Android Developers — AudioTrack"
[4]: https://developer.android.com/reference/android/media/AudioTimestamp "Android Developers — AudioTimestamp"
