# CapturePilot

**Professional photography, guided — not automated.**  
**Fotografía profesional, guiada — no automatizada.**

CapturePilot is a free, ad-free iOS camera that combines professional capture controls with an on-device photography coach. The coach prioritizes practical suggestions and does not assign an aesthetic score or replace the photographer's creative decisions.

CapturePilot es una cámara gratuita y sin anuncios para iOS que combina controles profesionales con un coach fotográfico local. El coach prioriza sugerencias prácticas; no asigna una puntuación estética ni sustituye las decisiones creativas del fotógrafo.

> **Current main / main actual: 0.4.0 (4).** Release compilation is verified in CI for both iOS Simulator and iPhoneOS. Physical-device testing, signed Archive validation, and App Store Connect processing remain release gates.

## English

### Capture

- Edge-to-edge rear-camera viewfinder with adaptive AVFoundation rotation.
- Physical Ultra Wide, Wide, and Telephoto discovery when the device exposes them.
- Lens labels derived from optical field-of-view instead of a generic “Tele” label.
- HEIF using HEVC **only when the current photo output supports HEVC**.
- JPEG.
- Bayer RAW/DNG only when the active pipeline exposes a Bayer RAW pixel format.
- Apple ProRAW only when `AVCapturePhotoOutput` reports ProRAW support.
- The camera selects a maximum-resolution photo format for each physical lens.
- Resolution options come directly from `AVCaptureDevice.Format.supportedMaxPhotoDimensions`.
- 12 MP, 24 MP, and 48 MP appear when the active hardware/format exposes matching dimensions; other valid dimensions remain capability-driven.
- `AVCapturePhotoOutput.maxPhotoDimensions` is configured to the active format's maximum supported dimensions.
- Every capture explicitly sets `AVCapturePhotoSettings.maxPhotoDimensions`.
- Add-only save to Photos.
- Tap-to-focus and tap-to-meter.

### Professional controls

- EV compensation when supported.
- Auto/manual exposure.
- ISO and shutter duration.
- Auto/manual focus and lens position.
- Auto/manual white balance and color temperature.
- Unsupported manual controls are hidden instead of presenting controls that cannot work.
- Resolution selector in the Pro controls.

### Composition coach

All analysis is on-device.

Current signals include:

- horizon;
- face/person detection;
- attention-based saliency;
- sampled luminance and approximate highlight/shadow clipping;
- rule-of-thirds proximity;
- person headroom;
- leading-line estimation;
- symmetry score;
- vanishing-point estimation;
- negative-space estimation;
- edge/detail signal for macro guidance;
- golden-spiral strong-point guidance;
- golden-triangle guidance.

The geometric analysis is intentionally heuristic. It is guidance, not a claim that every detected line, vanishing point, or compositional judgment is objectively correct.

### Scene-specific coaches

The photographer explicitly chooses the scene coach; CapturePilot does not pretend to classify every scene automatically.

- General
- Portrait
- Architecture
- Automotive
- Macro
- Street
- Landscape
- Night

Each mode changes the priority of real analysis signals. For example, Architecture emphasizes horizon/symmetry/vanishing geometry, Macro prioritizes detail and golden-point placement, and Night changes exposure thresholds and stabilization guidance.

### Composition overlays

- Rule of thirds
- Golden-ratio grid
- Golden spiral
- Golden triangle
- Crosshair
- Level indicator
- In Teaching mode, detected leading-line geometry and a usable vanishing point can be visualized.

### Orientation and HUD

- Standard portrait.
- Landscape left/right, independently disableable as a group.
- Upside-down portrait, independently disableable.
- AVFoundation `RotationCoordinator` keeps preview/capture connections aligned with device orientation.
- Customizable HUD with separate portrait and landscape positions.
- HUD items stay clamped to the safe area.
- Optional dedicated Focus Peaking button.
- Settings and shutter remain non-hideable recovery controls.

### Focus Peaking

Focus Peaking uses the luminance plane already delivered by the camera pipeline and highlights strong local edges. It is a contrast-based focusing aid, not an absolute focus-confidence measurement.

### Session recovery

CapturePilot observes:

- SwiftUI `scenePhase`;
- `AVCaptureSession.wasInterruptedNotification`;
- `AVCaptureSession.interruptionEndedNotification`;
- `AVCaptureSession.runtimeErrorNotification`.

Returning from Settings/foreground rechecks camera authorization and restarts the session when possible. A media-services reset triggers a recovery attempt.

### Language

- Follow System
- English
- Español

Language, guide, coach mode/intensity, orientation settings, and HUD layout persist locally.

### Privacy

- No CapturePilot account.
- No ads.
- No third-party analytics SDK.
- No CapturePilot cloud service.
- No live-frame upload.
- Coach, geometry analysis, and Focus Peaking run on-device.
- Privacy Manifest declares no tracking or collected-data types.
- UserDefaults Required Reason API: CA92.1.

### Build / release status

- Minimum deployment target: iOS 17.
- Current version/build: **0.4.0 (4)**.
- GitHub Actions compiles Release for iOS Simulator and iPhoneOS.
- Physical camera behavior, 12/24/48 MP availability, RAW/ProRAW output, Dynamic Island/notch geometry, rotation, and real sensor behavior still require device acceptance.
- TestFlight is not considered validated until a signed Archive passes Xcode validation and App Store Connect processes the upload.

---

## Español

### Captura

- Visor trasero de borde a borde con rotación adaptativa mediante AVFoundation.
- Descubrimiento de Ultra Wide, Wide y Telephoto físicos cuando el dispositivo los expone.
- Etiquetas de lente calculadas a partir del campo de visión, en vez de mostrar un “Tele” genérico.
- HEIF mediante HEVC **únicamente cuando el output actual soporta HEVC**.
- JPEG.
- Bayer RAW/DNG sólo cuando el pipeline activo expone un formato Bayer RAW.
- Apple ProRAW sólo cuando `AVCapturePhotoOutput` reporta compatibilidad.
- Selección del formato fotográfico de máxima resolución disponible por lente.
- Las resoluciones provienen de `supportedMaxPhotoDimensions`.
- 12 MP, 24 MP y 48 MP aparecen cuando el hardware/formato activo realmente ofrece dimensiones equivalentes.
- `AVCapturePhotoOutput.maxPhotoDimensions` se configura con el máximo válido del formato.
- Cada captura configura explícitamente `AVCapturePhotoSettings.maxPhotoDimensions`.
- Guardado add-only en Fotos.
- Tap-to-focus y medición al tocar.

### Controles profesionales

- Compensación EV cuando está disponible.
- Exposición automática/manual.
- ISO y obturación.
- Enfoque automático/manual y posición de lente.
- Balance de blancos automático/manual y temperatura.
- Los controles manuales no compatibles se ocultan en lugar de presentar funciones inactivas.
- Selector de resolución dentro de los controles Pro.

### Coach de composición

Todo el análisis ocurre en el dispositivo.

Se analizan:

- horizonte;
- rostro/persona;
- saliencia visual;
- luminancia y clipping aproximado;
- regla de tercios;
- headroom;
- líneas guía;
- simetría;
- punto de fuga;
- espacio negativo;
- señal de detalle para Macro;
- puntos de espiral áurea;
- geometría de triángulo áureo.

El análisis geométrico es deliberadamente heurístico: es una ayuda fotográfica, no una afirmación de que cada línea, punto de fuga o decisión compositiva sea objetivamente correcta.

### Coaches específicos

La persona elige explícitamente el tipo de escena; CapturePilot no finge clasificar automáticamente cualquier situación.

- General
- Retrato
- Arquitectura
- Automotriz
- Macro
- Calle
- Paisaje
- Noche

Cada modo cambia la prioridad de señales reales. Arquitectura enfatiza horizonte/simetría/punto de fuga; Macro prioriza detalle y puntos áureos; Noche modifica umbrales de exposición y prioriza estabilidad.

### Guías de composición

- Regla de tercios
- Proporción áurea
- Espiral áurea
- Triángulo áureo
- Cruz
- Nivel
- En modo Didáctico pueden visualizarse líneas detectadas y el punto de fuga útil.

### Orientación y HUD

- Vertical normal.
- Horizontal izquierda/derecha, desactivable.
- Vertical invertido, desactivable de forma independiente.
- `RotationCoordinator` alinea preview y captura.
- HUD personalizable con posiciones separadas vertical/horizontal.
- Los elementos permanecen dentro del área segura.
- Botón opcional dedicado a Focus Peaking.
- Ajustes y disparador no pueden ocultarse.

### Focus Peaking

Focus Peaking analiza contraste local en el plano de luminancia del mismo pipeline de cámara. Es una ayuda visual de enfoque, no una medición absoluta del plano focal.

### Recuperación de sesión

CapturePilot observa:

- `scenePhase`;
- `AVCaptureSession.wasInterruptedNotification`;
- `AVCaptureSession.interruptionEndedNotification`;
- `AVCaptureSession.runtimeErrorNotification`.

Al volver de Ajustes/foreground se revisa de nuevo el permiso y se intenta reanudar la sesión. Un reset de media services dispara recuperación.

### Idioma

- Igualar al Sistema
- English
- Español

Idioma, guía, escena/intensidad del coach, orientación y HUD se guardan localmente.

### Privacidad

- Sin cuenta.
- Sin publicidad.
- Sin SDK de analítica de terceros.
- Sin nube de CapturePilot.
- Sin subida de frames.
- Coach, geometría y Focus Peaking son locales.
- Privacy Manifest sin tracking ni tipos de datos recopilados.
- Required Reason API de UserDefaults: CA92.1.

### Build / estado de publicación

- iOS 17 mínimo.
- Versión/build actual: **0.4.0 (4)**.
- GitHub Actions compila Release para Simulator e iPhoneOS.
- Cámara física, disponibilidad real 12/24/48 MP, RAW/ProRAW, Dynamic Island/notch, orientación y sensores todavía requieren aceptación en dispositivo.
- TestFlight sólo se considera validado después de Archive firmado + Validate App + procesamiento correcto en App Store Connect.

## Documentation / Documentación

- [Architecture / Arquitectura](docs/ARCHITECTURE.md)
- [Roadmap / Hoja de ruta](docs/ROADMAP.md)
- [Device testing / Pruebas físicas](docs/TESTING.md)
- [UI layout / Pantalla completa](docs/UI_LAYOUT.md)
- [TestFlight](docs/TESTFLIGHT.md)
- [Privacy / Privacidad](docs/PRIVACY.md)
- [App Store metadata](docs/APP_STORE_METADATA.md)
- [Changelog / Registro de cambios](CHANGELOG.md)

## Technology

SwiftUI · AVFoundation · Vision · Photos · Core Video

## License / Licencia

CapturePilot is released under the [MIT License](LICENSE). / CapturePilot se publica bajo la [Licencia MIT](LICENSE).
