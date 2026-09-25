# Device Test Checklist / Lista de pruebas físicas

## English

Record device, iOS, Xcode, CapturePilot version/build, and console errors.

### Build and permissions

- [ ] Release installs and launches.
- [ ] Camera permission is localized.
- [ ] Deny → recovery screen works.
- [ ] Open Settings, grant Camera, return: preview recovers without relaunching the app.
- [ ] Photos add-only permission is localized.

### Session lifecycle

- [ ] Background → foreground restores the camera.
- [ ] Lock/unlock restores the camera.
- [ ] Temporary camera interruption displays status and recovers.
- [ ] Media-services reset path does not leave the shutter permanently disabled.
- [ ] No duplicate session inputs/outputs after repeated resume cycles.

### Lenses

- [ ] 0.5× appears only if a physical Ultra Wide exists.
- [ ] Wide works.
- [ ] Tele appears only when a physical telephoto exists.
- [ ] Labels are sensible for the hardware.
- [ ] Switching lenses does not freeze.
- [ ] Rotation remains correct after switching.
- [ ] Manual-control availability refreshes after switching.

### Resolution / formats

For each lens:

- [ ] Record every displayed resolution.
- [ ] Confirm 12 MP only appears when a matching supported dimension exists.
- [ ] Confirm 24 MP only appears when supported.
- [ ] Confirm 48 MP only appears when supported.
- [ ] Capture each displayed resolution and inspect actual pixel dimensions.
- [ ] HEIF appears only when HEVC is supported.
- [ ] HEIF produces a valid HEIF/HEVC-backed asset.
- [ ] JPEG produces a valid JPEG asset.
- [ ] Bayer RAW appears only when a Bayer RAW pixel format exists.
- [ ] RAW saves a readable DNG/RAW asset.
- [ ] ProRAW appears only on supported configurations.
- [ ] ProRAW saves a readable Apple ProRAW asset.

### Manual controls

- [ ] Unsupported controls are absent.
- [ ] EV changes exposure.
- [ ] Manual ISO/shutter works where advertised.
- [ ] AF ↔ manual focus works.
- [ ] AWB ↔ manual WB works.
- [ ] Tap-to-focus resets manual focus/exposure cleanly.

### Coach

Test all eight scene modes.

- [ ] Horizon guidance reacts to tilt.
- [ ] Bright/dark thresholds behave sensibly.
- [ ] Person/headroom behavior works in Portrait.
- [ ] Architecture reacts to symmetry/vanishing geometry.
- [ ] Automotive/Street reacts to clear converging/leading lines.
- [ ] Macro reacts to detail and golden-point placement.
- [ ] Landscape reacts to horizon/golden-triangle/lines.
- [ ] Night does not simply flag every dark scene as invalid.
- [ ] Suggestions remain stabilized.

### Composition overlays

- [ ] Thirds.
- [ ] Golden ratio.
- [ ] Golden spiral.
- [ ] Golden triangle.
- [ ] Crosshair.
- [ ] Level.
- [ ] Teaching-mode leading-line overlay aligns approximately with visible geometry.
- [ ] Vanishing-point marker does not appear wildly off-screen during ordinary use.

### Orientation/HUD/Focus Peaking

- [ ] Portrait.
- [ ] Landscape left/right.
- [ ] Upside-down portrait.
- [ ] Disable Landscape works.
- [ ] Disable Upside-down works.
- [ ] HUD positions persist separately by orientation.
- [ ] HUD elements remain inside safe areas.
- [ ] Focus Peaking button can be shown/hidden.
- [ ] Peaking aligns with the preview in every orientation/lens.
- [ ] Entering HUD edit disables active peaking.

### Zebras / Histogram

- [ ] Zebra button toggles the overlay without affecting AF/AE gestures.
- [ ] Presets 75/80/85/90/95/100 update immediately.
- [ ] Settings slider covers the full 75–100 range.
- [ ] Zebra stripes appear only at/above the selected preview-luma threshold.
- [ ] Zebra overlay aligns in portrait, both landscapes, and upside-down.
- [ ] Zebra alignment remains correct after switching lenses.
- [ ] Histogram appears when the HUD item is visible.
- [ ] RGB channels react plausibly to strongly red/green/blue scenes.
- [ ] Highlight clipping indicator reacts to clipped bright channels.
- [ ] Shadow clipping indicator reacts to crushed dark channels.
- [ ] Tap histogram expands and collapses without leaving the safe area.
- [ ] Hiding Histogram stops its live processing.
- [ ] Monitoring + Peaking + Coach together do not cause unacceptable preview stutter or thermal load in a short smoke test.

### Release

- [ ] Product > Archive.
- [ ] Validate App.
- [ ] Version/build is 0.4.0 (4).
- [ ] App Store Connect processes the binary.
- [ ] Internal TestFlight install launches and captures.
- [ ] Crash-free smoke test.

---

## Español

Registra dispositivo, iOS, Xcode, versión/build y errores de consola.

### Build y permisos

- [ ] Release instala y abre.
- [ ] Permiso de cámara localizado.
- [ ] Negar permiso muestra recuperación.
- [ ] Abrir Ajustes, conceder Cámara y volver recupera el preview sin reiniciar la app.
- [ ] Permiso add-only de Fotos localizado.

### Ciclo de sesión

- [ ] Background → foreground recupera la cámara.
- [ ] Bloquear/desbloquear recupera la cámara.
- [ ] Una interrupción temporal muestra estado y termina recuperándose.
- [ ] Un reset de media services no deja el disparador inutilizable.
- [ ] Reanudar repetidamente no duplica inputs/outputs.

### Lentes

- [ ] 0.5× sólo aparece con Ultra Wide física.
- [ ] Wide funciona.
- [ ] Tele sólo aparece con telefoto física.
- [ ] Las etiquetas tienen sentido para el hardware.
- [ ] Cambiar de lente no congela.
- [ ] La rotación sigue correcta.
- [ ] Las capabilities manuales se actualizan.

### Resolución y formatos

Para cada lente:

- [ ] Registra todas las resoluciones mostradas.
- [ ] 12 MP sólo aparece si existe una dimensión equivalente.
- [ ] 24 MP sólo aparece si está soportada.
- [ ] 48 MP sólo aparece si está soportada.
- [ ] Captura cada resolución y verifica dimensiones reales.
- [ ] HEIF sólo aparece cuando HEVC está soportado.
- [ ] HEIF crea un asset válido.
- [ ] JPEG crea un asset válido.
- [ ] Bayer RAW sólo aparece con pixel format Bayer.
- [ ] RAW produce un archivo legible.
- [ ] ProRAW sólo aparece en configuraciones compatibles.
- [ ] ProRAW produce Apple ProRAW legible.

### Controles manuales

- [ ] Controles no soportados no aparecen.
- [ ] EV funciona.
- [ ] ISO/obturación manual funcionan donde se anuncian.
- [ ] AF ↔ manual focus.
- [ ] AWB ↔ WB manual.
- [ ] Tap-to-focus restablece estados manuales correctamente.

### Coach

Prueba los ocho modos.

- [ ] Horizonte.
- [ ] Luces/sombras.
- [ ] Persona/headroom en Retrato.
- [ ] Simetría/punto de fuga en Arquitectura.
- [ ] Líneas claras en Automotriz/Calle.
- [ ] Detalle/punto áureo en Macro.
- [ ] Horizonte/triángulo/líneas en Paisaje.
- [ ] Noche no considera automáticamente inválida toda escena oscura.
- [ ] Mensajes estables.

### Guías

- [ ] Tercios.
- [ ] Proporción áurea.
- [ ] Espiral áurea.
- [ ] Triángulo áureo.
- [ ] Cruz.
- [ ] Nivel.
- [ ] Líneas detectadas aproximadamente alineadas en modo Didáctico.
- [ ] Punto de fuga razonable.

### Orientación/HUD/Peaking

- [ ] Vertical.
- [ ] Horizontal izquierda/derecha.
- [ ] Vertical invertido.
- [ ] Interruptores de orientación funcionan.
- [ ] HUD guarda posiciones independientes.
- [ ] Elementos no salen del área segura.
- [ ] Botón Peaking visible/oculto.
- [ ] Peaking se alinea en todas las orientaciones/lentes.
- [ ] Editar HUD desactiva Peaking.

### Cebras / Histograma

- [ ] El botón Zebra activa/desactiva sin interferir con AF/AE.
- [ ] Presets 75/80/85/90/95/100 se aplican al instante.
- [ ] Slider de Ajustes cubre 75–100.
- [ ] Las líneas aparecen sólo al alcanzar/superar el umbral del preview.
- [ ] Alineación correcta en vertical, ambos horizontales e invertido.
- [ ] Alineación correcta tras cambiar lente.
- [ ] Histograma visible cuando su elemento HUD está activo.
- [ ] Canales RGB reaccionan de forma razonable a escenas dominantes por color.
- [ ] Indicadores de clipping reaccionan a luces/sombras recortadas.
- [ ] Tocar el histograma expande/contrae sin salir del área segura.
- [ ] Ocultar Histograma detiene su procesamiento.
- [ ] Zebra + Histograma + Peaking + Coach no generan stutter/carga térmica inaceptable en una prueba corta.

### Publicación

- [ ] Archive.
- [ ] Validate App.
- [ ] 0.4.0 (4).
- [ ] App Store Connect procesa.
- [ ] TestFlight interno.
- [ ] Smoke test sin crashes.
