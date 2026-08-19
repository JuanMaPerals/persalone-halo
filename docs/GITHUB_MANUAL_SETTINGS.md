# Ajustes manuales de GitHub pendientes

**Estado al 2026-08-19:** estos controles no se configuran mediante código del repositorio y no se declaran activos. El propietario de `JuanMaPerals/persalone-halo` debe configurarlos y verificarlos en GitHub.

| Ajuste | Acción manual exacta | Resultado esperado | Evidencia a conservar |
|---|---|---|---|
| Protección de `main` | En **Settings → Branches → Add branch ruleset**, crear una regla para `main`. | Bloquea push directo; exige pull request antes de merge. | Captura de la regla y enlace a la configuración. |
| Revisión de PR | En la misma ruleset, activar al menos una aprobación y desestimar aprobaciones obsoletas al recibir nuevos commits. | Ningún cambio llega a `main` sin revisión humana. | Checks de una PR de prueba. |
| Checks requeridos | Añadir como checks requeridos `verify`, `secret-scan` y `sbom` cuando los workflows hayan completado su primera ejecución. | No permite merge si falla análisis, tests o escaneo. | Ruleset con los checks seleccionados. |
| Bloqueo de force push y borrado | Desactivar force pushes y eliminación de rama protegida. | Conserva historial y recuperación operativa. | Ruleset activa. |
| Reporte privado de vulnerabilidades | En **Settings → Code security and analysis**, activar **Private vulnerability reporting** si está disponible para el plan del repositorio. | Existe un canal privado de reporte; si la función no está disponible, publicar una dirección de contacto privada controlada por el propietario en `SECURITY.md`. | Pantalla de estado o prueba de flujo privado. |
| Dependabot alerts y secret scanning | Activar Dependabot alerts y GitHub secret scanning/push protection si están disponibles para el plan y visibilidad actuales. | Señales adicionales gestionadas por GitHub sobre dependencias y secretos. | Pantalla de estado; no sustituye los workflows del repositorio. |
| Acceso de GitHub Actions | Mantener el token predeterminado de Actions en lectura; no habilitar secretos de despliegue ni permisos de escritura para esta fase. | El CI solo lee el repositorio y ejecuta checks. | Configuración de Actions. |
| Propietarios y revisión | Validar que `@JuanMaPerals` mantiene ownership y añadir revisores adicionales solo cuando existan mantenedores identificados. | Accountability explícita de revisión. | `CODEOWNERS` y configuración de acceso. |

> No habilitar publicación en tiendas, despliegues, OTA, secretos de proveedores, credenciales de backend ni automatización de release como parte de G0/G1.
