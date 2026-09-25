# CapturePilot

**Professional photography, guided — not automated.**

CapturePilot is a free, ad-free iOS camera that combines professional camera controls with an on-device photography coach. The coach offers prioritized guidance without assigning an aesthetic score or replacing the photographer's creative decisions.

> Status: **0.3.0 (3) — orientation + customizable HUD candidate. Release compilation is verified in CI; physical-device layout/camera testing, signed Archive validation, and App Store Connect processing remain release gates.**

## English

### Implemented

**Camera**
- Edge-to-edge rear-camera viewfinder.
- Ultra Wide, Wide, and Telephoto discovery when the device exposes those cameras.
- HEIF and JPEG capture.
- RAW/DNG option only when the active camera configuration reports support.
- Add-only save to Photos.
- Tap-to-focus and tap-to-meter.
- Rotation-aware preview and capture using AVFoundation's rotation coordinator.

**Orientation**
- Standard portrait is always available.
- Landscape-left and landscape-right support.
- Upside-down portrait support.
- Landscape can be disabled independently.
- Upside-down portrait can be disabled independently.
- The allowed-orientation preference persists locally.

**Manual controls**
- EV compensation.
- Auto/manual exposure.
- ISO and shutter duration.
- Auto/manual focus and lens position.
- Auto/manual white balance and color temperature.

**On-device coach**
- Horizon analysis.
- Face/person detection.
- Attention-based saliency.
- Sampled luminance and approximate highlight/shadow clipping signals.
- Rule-of-thirds strong-point guidance.
- Headroom guidance for detected people.
- Stabilized recommendations.
- Subtle, Balanced, and Teaching modes.

**Customizable HUD**
- HUD editing mode launched from Settings.
- Drag HUD elements freely inside the current safe area.
- Separate saved positions for portrait and landscape.
- Show/hide optional HUD elements.
- Hidden elements remain available as ghosts while editing so they can be restored/repositioned.
- Shutter and Settings remain required so the camera cannot be configured into an unrecoverable layout.
- Reset-to-default layout.
- Movable Pro button, language selector, lens selector, coach, metrics, format, shutter, grid, Settings and optional Focus Peaking access.

**Focus Peaking**
- Real-time edge-contrast overlay derived locally from the camera luminance plane.
- Separate quick-access HUD button; no press-and-hold gesture on the viewfinder is required.
- Single tap toggles the overlay.
- Quick-access button is optional and hidden by default.
- Peaking is intentionally separate from tap-to-focus and leaves long-press space available for future AF/AE-lock behavior.

**Interface/language**
- Full-screen shooting surface with safe-area-aware controls.
- Rule of thirds, golden-ratio grid, crosshair, and level indicator.
- Direct language button plus Settings selector.
- English, Spanish, or follow System.
- Persistent app preferences.

**Distribution/privacy**
- AppIcon and launch assets.
- Privacy Manifest with no tracking or collected-data declarations.
- Required Reason API declaration for app-local UserDefaults (CA92.1).
- No account, advertising, third-party analytics SDK, or CapturePilot cloud service in the current source.

### Not implemented

The repository does **not** currently claim these as working features:

- Zebra overlays.
- Histogram.
- ProRAW-specific workflow.
- Bracketing.
- Dedicated AF/AE long-press lock.
- Scene-specific Portrait/Architecture/Automotive/Macro/Street/Landscape/Night coaches.
- Leading-line, symmetry, vanishing-point, negative-space, golden-spiral, or golden-triangle analysis.
- Cloud AI or post-capture cloud review.

### Build and TestFlight

- Minimum deployment target: iOS 17.
- Current version/build: **0.3.0 (3)**.
- Release compilation is checked against Simulator and iPhoneOS SDKs with Xcode 26.x in GitHub Actions.
- Orientation, safe-area behavior, peaking alignment and drag boundaries still require physical-device validation before external TestFlight testing.

Documentation:
- [Architecture](docs/ARCHITECTURE.md)
- [Device testing](docs/TESTING.md)
- [Full-screen/HUD validation](docs/UI_LAYOUT.md)
- [Privacy](docs/PRIVACY.md)
- [TestFlight guide](docs/TESTFLIGHT.md)
- [App Store/TestFlight metadata](docs/APP_STORE_METADATA.md)
- [Roadmap](docs/ROADMAP.md)

---

## Español

CapturePilot es una cámara gratuita y sin anuncios para iOS que combina controles fotográficos profesionales con un coach local. El coach ofrece sugerencias priorizadas sin asignar una puntuación estética ni sustituir la intención del fotógrafo.

> Estado: **0.3.0 (3) — candidato con orientaciones y HUD personalizable. La compilación Release se valida en CI; todavía quedan la prueba física, Archive firmado y procesamiento por App Store Connect.**

### Implementado

**Cámara**
- Visor trasero de borde a borde.
- Detección de Ultra Wide, Wide y Telephoto cuando el dispositivo las expone.
- HEIF y JPEG.
- RAW/DNG solo cuando la configuración activa informa compatibilidad.
- Guardado en Fotos con permiso solo para agregar.
- Tap-to-focus y medición al tocar.
- Preview y captura conscientes de la rotación mediante el coordinador de AVFoundation.

**Orientación**
- Vertical normal siempre disponible.
- Horizontal a ambos lados.
- Vertical invertido.
- Horizontal puede desactivarse.
- Vertical invertido puede desactivarse independientemente.
- Preferencias persistentes.

**Controles manuales**
- EV.
- Exposición automática/manual.
- ISO y tiempo de obturación.
- Enfoque automático/manual y posición de lente.
- Balance de blancos automático/manual y temperatura de color.

**Coach local**
- Horizonte.
- Rostro/persona.
- Saliencia visual.
- Luminancia y señales aproximadas de clipping.
- Regla de tercios.
- Headroom.
- Recomendaciones estabilizadas.
- Modos Sutil, Equilibrado y Didáctico.

**HUD personalizable**
- Modo de edición desde Ajustes.
- Los elementos pueden desplazarse libremente dentro del área segura.
- Posiciones distintas guardadas para vertical y horizontal.
- Elementos opcionales se pueden mostrar u ocultar.
- Durante edición, los ocultos aparecen como fantasmas para poder recuperarlos/moverlos.
- Disparador y Ajustes permanecen obligatorios para evitar un layout irrecuperable.
- Restablecimiento a valores predeterminados.
- Son movibles: Pro, idioma, lentes, coach, métricas, formato, disparador, guía, Ajustes y acceso opcional a Focus Peaking.

**Focus Peaking**
- Overlay en tiempo real basado en contraste de bordes de la señal de luminancia de cámara.
- Botón HUD específico; no requiere mantener presionada la pantalla.
- Un toque activa/desactiva el overlay.
- El botón es opcional y está oculto por defecto.
- Se mantiene separado de tap-to-focus y no ocupa un gesto de pulsación larga que pueda usarse después para AF/AE Lock.

**Interfaz/idioma**
- Cámara a pantalla completa con controles dentro de safe areas.
- Tercios, proporción áurea, cruz e indicador de nivel.
- Botón directo de idioma y selector en Ajustes.
- Español, English o igualar al Sistema.
- Preferencias persistentes.

**Distribución/privacidad**
- AppIcon y recursos de lanzamiento.
- Privacy Manifest sin tracking ni tipos de datos recopilados.
- UserDefaults declarado con motivo CA92.1 para ajustes locales.
- Sin cuenta, publicidad, SDK de analítica de terceros ni nube de CapturePilot.

### No implementado

El repositorio **no** presenta todavía como funcional:

- Zebras.
- Histograma.
- Flujo específico ProRAW.
- Bracketing.
- Bloqueo AF/AE dedicado mediante pulsación larga.
- Coaches específicos por escena.
- Líneas guía, simetría, punto de fuga, espacio negativo, espiral/triángulo áureo.
- IA en la nube o revisión cloud posterior.

### Build y TestFlight

- Deployment target mínimo: iOS 17.
- Versión/build: **0.3.0 (3)**.
- CI comprueba Release contra Simulator e iPhoneOS con Xcode 26.x.
- Orientación, safe areas, alineación del peaking y límites de arrastre deben probarse físicamente antes de TestFlight externo.

## Technology

SwiftUI · AVFoundation · Vision · Photos · Core Video

## Product rule

A feature is described as implemented only when code exists. Hardware/layout behavior is marked as device-validated only after physical testing. TestFlight acceptance is claimed only after App Store Connect processes the uploaded archive.
