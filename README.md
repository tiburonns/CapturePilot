# CapturePilot

**Professional photography, guided — not automated.**

CapturePilot is a free, ad-free iOS camera that combines professional camera controls with an on-device photography coach. The coach offers one prioritized suggestion at a time; it does not assign an aesthetic score or make creative decisions for the photographer.

> Status: **0.2.0 (2) — source-complete TestFlight candidate. Physical-device, Xcode Archive, and App Store Connect processing are still release gates.**

## English

### Implemented

**Camera**
- Edge-to-edge rear-camera viewfinder.
- Ultra Wide, Wide, and Telephoto discovery when the device exposes those cameras.
- HEIF and JPEG capture.
- RAW/DNG option only when `AVCapturePhotoOutput` reports RAW support for the active configuration.
- Add-only save to Photos.
- Tap-to-focus and tap-to-meter.

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

**Interface**
- Full-screen shooting surface with safe-area-aware controls.
- Hidden shooting status bar.
- Rule of thirds, golden-ratio grid, crosshair, and level indicator.
- Direct language button in the camera plus Settings selector.
- English, Spanish, or follow System language.
- Persistent language/grid/coach preferences.

**Distribution/privacy**
- AppIcon asset catalog and dark launch background.
- Privacy Manifest with no tracking or collected-data declarations.
- Required Reason API declaration for app-local `UserDefaults` (CA92.1).
- No account, advertising, third-party analytics SDK, or CapturePilot cloud service in the current source.
- `ITSAppUsesNonExemptEncryption = NO` for the current source, which contains no custom/non-exempt encryption.

### Not implemented

The repository does **not** currently claim these as working features:

- Focus peaking.
- Zebra overlays.
- Histogram.
- ProRAW-specific workflow.
- Bracketing.
- Scene-specific Portrait/Architecture/Automotive/Macro/Street/Landscape/Night coaches.
- Leading-line, symmetry, vanishing-point, negative-space, golden-spiral, or golden-triangle analysis.
- Cloud AI or post-capture cloud review.

See [ROADMAP](docs/ROADMAP.md).

### Build and TestFlight

- Minimum deployment target: iOS 17.
- Current app version/build: 0.2.0 (2).
- Open `CapturePilot.xcodeproj`.
- Select your Apple Developer Team and confirm the final Bundle Identifier.
- Use Xcode 26 or later for 2026 App Store Connect uploads.
- Complete the physical-device checklist before external testing.

Documentation:
- [Architecture](docs/ARCHITECTURE.md)
- [Device testing](docs/TESTING.md)
- [Full-screen UI validation](docs/UI_LAYOUT.md)
- [Privacy](docs/PRIVACY.md)
- [TestFlight release guide](docs/TESTFLIGHT.md)
- [App Store/TestFlight metadata draft](docs/APP_STORE_METADATA.md)

---

## Español

CapturePilot es una cámara gratuita y sin anuncios para iOS que combina controles fotográficos profesionales con un coach que analiza la escena en el dispositivo. El coach presenta una recomendación prioritaria; no asigna una puntuación estética ni sustituye las decisiones creativas del fotógrafo.

> Estado: **0.2.0 (2) — candidato de código para TestFlight. La prueba física, Archive en Xcode y procesamiento de App Store Connect siguen siendo puertas de publicación.**

### Implementado

**Cámara**
- Visor trasero de borde a borde.
- Detección de Ultra Wide, Wide y Telephoto cuando el dispositivo expone esas cámaras.
- HEIF y JPEG.
- RAW/DNG únicamente cuando `AVCapturePhotoOutput` reporta compatibilidad en la configuración activa.
- Guardado en Fotos con permiso solo para agregar.
- Tap-to-focus y medición de exposición al tocar.

**Controles manuales**
- EV.
- Exposición automática/manual.
- ISO y tiempo de obturación.
- Enfoque automático/manual y posición de lente.
- Balance de blancos automático/manual y temperatura de color.

**Coach local**
- Horizonte.
- Detección de rostro/persona.
- Saliencia visual.
- Muestreo de luminancia y señales aproximadas de recorte de luces/sombras.
- Guía de puntos fuertes de regla de tercios.
- Headroom para personas detectadas.
- Recomendaciones estabilizadas.
- Modos Sutil, Equilibrado y Didáctico.

**Interfaz**
- Superficie de cámara a pantalla completa con controles que respetan safe areas.
- Barra de estado oculta durante la captura.
- Regla de tercios, proporción áurea, cruz e indicador de nivel.
- Botón directo de idioma en la cámara y selector adicional en Ajustes.
- Inglés, Español o igualar al Sistema.
- Preferencias persistentes.

**Distribución/privacidad**
- AppIcon en asset catalog y fondo oscuro de lanzamiento.
- Privacy Manifest sin tracking ni tipos de datos recopilados.
- Declaración Required Reason API para `UserDefaults` local (CA92.1).
- Sin cuenta, anuncios, SDK de analítica de terceros ni nube de CapturePilot en el código actual.
- `ITSAppUsesNonExemptEncryption = NO` para el código actual, que no contiene cifrado personalizado/no exento.

### No implementado

El repositorio **no** presenta todavía como funcional:

- Focus peaking.
- Zebras.
- Histograma.
- Flujo específico ProRAW.
- Bracketing.
- Coaches específicos Retrato/Arquitectura/Automotriz/Macro/Calle/Paisaje/Noche.
- Análisis de líneas guía, simetría, punto de fuga, espacio negativo, espiral o triángulo áureo.
- IA en la nube o revisión cloud posterior.

Consulta [ROADMAP](docs/ROADMAP.md).

### Build y TestFlight

- Deployment target mínimo: iOS 17.
- Versión/build actual: 0.2.0 (2).
- Abre `CapturePilot.xcodeproj`.
- Selecciona tu Apple Developer Team y confirma el Bundle Identifier final.
- Usa Xcode 26 o posterior para uploads de App Store Connect durante 2026.
- Completa la lista de prueba física antes de testers externos.

Documentación:
- [Arquitectura](docs/ARCHITECTURE.md)
- [Pruebas](docs/TESTING.md)
- [Validación de pantalla completa](docs/UI_LAYOUT.md)
- [Privacidad](docs/PRIVACY.md)
- [Guía TestFlight](docs/TESTFLIGHT.md)
- [Borrador de metadata](docs/APP_STORE_METADATA.md)

## Technology

SwiftUI · AVFoundation · Vision · Photos

## Product rule

A capability is described as implemented only when source code exists. Hardware-dependent behavior is described as supported only when it is capability-gated. TestFlight acceptance is not claimed until App Store Connect processes an uploaded archive.
