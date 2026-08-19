# Política de seguridad

## Código soportado

| Línea de versión | Correcciones de seguridad |
| --- | --- |
| `0.3.x` release candidates | Mejor esfuerzo durante la vista previa comunitaria |
| Versiones anteriores | No |

Este repositorio contiene una base local-first de PersalOne Halo. No declara todavía una ruta de audio de producción, transporte físico Halo, proveedor cloud, servicio conectado ni capacidad clínica. Estos límites no reducen la obligación de reportar un problema de seguridad o privacidad.

## Reportar una vulnerabilidad

No abras una incidencia pública ni incluyas exploits, credenciales, audio, transcripciones, datos personales, identificadores de dispositivos o información de clientes en una pull request.

El repositorio existe, pero el reporte privado de vulnerabilidades de GitHub sigue pendiente de activación y verificación por el propietario. Consulta [los ajustes manuales de GitHub](docs/GITHUB_MANUAL_SETTINGS.md). Hasta que el estado se compruebe, solicita al propietario una ruta privada antes de compartir detalles técnicos. Si la función de GitHub no está disponible, el propietario debe publicar una dirección privada controlada en este documento.

Incluye una descripción concisa, revisión afectada, pasos de reproducción, impacto y mitigación segura. Sanea todo material de apoyo; un proof of concept sintético y mínimo es preferible a datos reales.

## Expectativas de tratamiento

Los mantenedores confirmarán un reporte válido por el canal privado, lo clasificarán y coordinarán la corrección y el momento de divulgación. No divulgues una vulnerabilidad sospechada hasta que un mantenedor confirme que es seguro hacerlo. Si existe riesgo inmediato para personas, privacidad o sistemas, detén las pruebas y utiliza la vía privada más rápida disponible.

## Ejemplos de alcance

Están dentro de alcance la exposición local, manejo de rutas de archivo, integridad de paquetes o build, secretos, límites de capacidades y regresiones de privacidad. El comportamiento de hardware, proveedor o navegador externo también puede reportarse cuando la integración o documentación de este repositorio introduce una suposición insegura.

No están dentro de alcance las peticiones para tratar simulación como certificación médica, jurídica, de seguridad o de dispositivo físico. Esas afirmaciones no son compatibles con esta fase del proyecto.
