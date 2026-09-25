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

### RAW + Share JPEG workflow

On every lens where RAW+JPG becomes available:

- [ ] RAW+JPG HUD label appears only when the capability gate is satisfied.
- [ ] One shutter press yields RAW and processed results from the same capture request.
- [ ] Record actual RAW/ProRAW pixel dimensions.
- [ ] Confirm the requested maximum is approximately 48 MP on the intended Wide-camera configuration.
- [ ] Confirm CapturePilot never advertises a synthetic 48 MP workflow on unsupported lenses.
- [ ] 12 MP target produces approximately 12 MP JPEG.
- [ ] 24 MP target produces approximately 24 MP JPEG.
- [ ] 48 MP target never upscales when the processed source is smaller.
- [ ] RAW data remains visually/data-wise unaffected by LUT choice.
- [ ] Import a known 17³ .cube LUT.
- [ ] Import a known 33³ .cube LUT.
- [ ] Import a known 65³ .cube LUT.
- [ ] Invalid/1D/non-standard-domain LUT produces a controlled error.
- [ ] LUT intensity 0% approximates the un-LUT processed JPEG.
- [ ] LUT intensity 100% applies the full transform.
- [ ] JPEG orientation is correct in every supported device orientation.
- [ ] JPEG is sRGB and readable by Photos/Files/share targets.
- [ ] Photos imports JPEG+RAW as one paired asset when supported.
- [ ] Fallback saves both files when pairing is rejected.
- [ ] Share Sheet sends the generated JPEG, not the RAW.
- [ ] Repeated captures clean up/replace temporary share files correctly.
- [ ] Maximum-resolution RAW+LUT JPEG processing does not cause an unacceptable memory spike/crash.

### Manual controls

- [ ] Unsupported controls are absent.
- [ ] EV changes exposure.
- [ ] Manual ISO/shutter works where advertised.
- [ ] AF ↔ manual focus works.
- [ ] AWB ↔ manual WB works.
- [ ] Tap-to-focus resets manual focus/exposure cleanly.

### Coach

Test all eight scene modes and record false positives, false negatives, and time-to-stable-message.

- [ ] Coach remains responsive without reacting to every preview frame.
- [ ] A new recommendation does not publish after only one transient analysis.
- [ ] Horizon guidance reacts to controlled tilt.
- [ ] Architecture/Landscape use visibly stricter leveling than general modes.
- [ ] Highlight warning reacts to controlled clipping.
- [ ] General-mode darkness warning behaves sensibly.
- [ ] Night does not simply flag every normally dark scene as invalid.
- [ ] Face/person detection drives Portrait headroom behavior.
- [ ] Attention saliency gives plausible subject placement when no person is present.
- [ ] Rule-of-thirds guidance changes direction appropriately around all four intersections.
- [ ] Architecture reacts to clear symmetry and converging geometry.
- [ ] Architecture does not report a confident vanishing point in obviously unsuitable scenes too often.
- [ ] Automotive reacts to clear leading lines / negative space.
- [ ] Street reacts to leading lines / negative space.
- [ ] Macro low-detail scenes produce refine-focus/stability guidance.
- [ ] Macro golden-point placement can produce positive guidance.
- [ ] Landscape reacts to golden-triangle/leading-line geometry.
- [ ] General strong-symmetry and strong-line thresholds behave plausibly.
- [ ] Teaching shows secondary reasoning and geometry overlays without changing the underlying Balanced decision unexpectedly.
- [ ] Subtle suppresses continuous composition coaching after capture-critical checks pass.
- [ ] Coach/geometry stays aligned across every supported orientation and physical lens.
- [ ] Coach + Peaking + professional scopes remain thermally acceptable in an extended device test.

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

### Advanced photography monitoring

- [ ] False Color aligns with the preview in every orientation/lens.
- [ ] False Color and Zebra do not remain active simultaneously.
- [ ] Luma Waveform reacts to left/right exposure differences.
- [ ] Waveform vertical scale behaves consistently from dark to bright.
- [ ] RGB Parade responds independently to dominant red/green/blue scenes.
- [ ] Vectorscope returns near center on neutral gray/white scenes.
- [ ] Vectorscope moves toward the expected hue direction on saturated targets.
- [ ] Scope expansion remains inside the safe area.
- [ ] Hiding each scope stops its requested processing.
- [ ] Peaking threshold visibly changes edge density.
- [ ] Every Peaking color renders correctly.
- [ ] Dual Zebra clearly distinguishes low and high bands.
- [ ] Clipping-warning HUD reports correct channel letters.
- [ ] Long press resolves the selected AF/AE point then locks.
- [ ] Tap after AF/AE Lock returns to automatic focus/meter behavior.
- [ ] Optional AF/AE HUD button locks/unlocks without a viewfinder gesture.
- [ ] Frame guides align correctly in portrait/landscape.
- [ ] Frame guides do not change captured pixel dimensions.
- [ ] Peaking + scopes + coach can run for 5 minutes without unacceptable stutter/thermal behavior.

### Release

- [ ] Product > Archive.
- [ ] Validate App.
- [ ] Version/build is 0.6.0 (6).
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

### Flujo RAW + JPEG para compartir

En cada lente donde RAW+JPG esté disponible:

- [ ] RAW+JPG sólo aparece cuando pasa el capability gate.
- [ ] Un disparo entrega RAW + processed del mismo request.
- [ ] Registrar dimensiones RAW/ProRAW reales.
- [ ] Confirmar ~48 MP en la configuración Wide prevista.
- [ ] No se anuncian 48 MP sintéticos en lentes no compatibles.
- [ ] JPEG 12 MP queda aproximadamente en 12 MP.
- [ ] JPEG 24 MP queda aproximadamente en 24 MP.
- [ ] Objetivo 48 MP nunca hace upscale.
- [ ] RAW no cambia con el LUT.
- [ ] Probar LUT conocido 17³, 33³ y 65³.
- [ ] LUT inválido/1D/dominio no estándar falla de forma controlada.
- [ ] Intensidad 0% se aproxima al processed sin LUT.
- [ ] Intensidad 100% aplica la transformación completa.
- [ ] Orientación JPEG correcta.
- [ ] JPEG sRGB legible.
- [ ] Fotos empareja JPEG+RAW cuando sea compatible.
- [ ] Fallback conserva ambos archivos.
- [ ] Share Sheet comparte JPEG, no RAW.
- [ ] Capturas repetidas gestionan temporales correctamente.
- [ ] Procesamiento máximo no provoca pico de memoria/crash inaceptable.

### Controles manuales

- [ ] Controles no soportados no aparecen.
- [ ] EV funciona.
- [ ] ISO/obturación manual funcionan donde se anuncian.
- [ ] AF ↔ manual focus.
- [ ] AWB ↔ WB manual.
- [ ] Tap-to-focus restablece estados manuales correctamente.

### Coach

Prueba los ocho modos y registra falsos positivos, falsos negativos y tiempo hasta mensaje estable.

- [ ] El Coach responde sin reaccionar a cada frame.
- [ ] Una recomendación nueva no se publica por un solo análisis transitorio.
- [ ] Horizonte responde a inclinación controlada.
- [ ] Arquitectura/Paisaje nivelan de forma más estricta que los modos generales.
- [ ] Aviso de luces responde a clipping controlado.
- [ ] Oscuridad en modo General se comporta de forma razonable.
- [ ] Noche no considera automáticamente inválida una escena normalmente oscura.
- [ ] Rostro/persona controla headroom en Retrato.
- [ ] Saliencia produce una ubicación plausible cuando no hay persona.
- [ ] Tercios cambia correctamente izquierda/derecha/arriba/abajo alrededor de las cuatro intersecciones.
- [ ] Arquitectura responde a simetría y convergencia claras.
- [ ] Arquitectura no inventa puntos de fuga con demasiada frecuencia en escenas no aptas.
- [ ] Automotriz responde a líneas/espacio negativo.
- [ ] Calle responde a líneas/espacio negativo.
- [ ] Macro con poco detalle recomienda refinar enfoque/estabilizar.
- [ ] Macro cerca de punto áureo puede producir guía positiva.
- [ ] Paisaje responde a triángulo áureo/líneas.
- [ ] Umbrales de simetría/líneas en General son razonables.
- [ ] Didáctico muestra razonamiento/overlays extra sin cambiar inesperadamente la decisión base de Equilibrado.
- [ ] Sutil deja de dar composición continua tras superar checks críticos.
- [ ] Coach/geometría se mantiene alineado en orientaciones y lentes físicas.
- [ ] Coach + Peaking + scopes mantienen carga térmica aceptable en prueba prolongada.

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

### Monitoreo fotográfico avanzado

- [ ] False Color coincide con el preview en orientaciones/lentes.
- [ ] False Color y Zebra no permanecen activos simultáneamente.
- [ ] Waveform reacciona a diferencias de exposición izquierda/derecha.
- [ ] Escala vertical coherente de oscuro a claro.
- [ ] RGB Parade responde por separado a escenas dominantes R/G/B.
- [ ] Vectorscope vuelve cerca del centro con gris/blanco neutro.
- [ ] Vectorscope se desplaza hacia el tono esperado con colores saturados.
- [ ] Scopes ampliados permanecen dentro del área segura.
- [ ] Ocultar cada scope detiene su procesamiento solicitado.
- [ ] El umbral de Peaking cambia visiblemente la densidad de bordes.
- [ ] Todos los colores de Peaking funcionan.
- [ ] Zebra dual distingue claramente banda baja/alta.
- [ ] Avisos de clipping muestran canales correctos.
- [ ] Pulsación larga resuelve el punto y bloquea AF/AE.
- [ ] Tocar después de AF/AE Lock devuelve el comportamiento automático.
- [ ] Botón HUD AF/AE bloquea/desbloquea sin gesto.
- [ ] Guías de formato correctas en vertical/horizontal.
- [ ] Las guías no cambian las dimensiones capturadas.
- [ ] Peaking + scopes + coach funcionan 5 minutos sin stutter/carga térmica inaceptable.

### Publicación

- [ ] Archive.
- [ ] Validate App.
- [ ] 0.6.0 (6).
- [ ] App Store Connect procesa.
- [ ] TestFlight interno.
- [ ] Smoke test sin crashes.
