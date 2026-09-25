# Roadmap / Hoja de ruta

## English

A checked source item means implementation exists and the project compiles. It does **not** mean the behavior has passed physical-device acceptance.

### 0.1 — Camera foundation

- [x] AVFoundation preview/capture.
- [x] HEIF/JPEG.
- [x] Capability-gated Bayer RAW.
- [x] Physical rear-lens discovery/switching.
- [x] EV / ISO / shutter / focus / white balance.
- [x] Tap-to-focus/meter.
- [x] Vision/luminance coach.
- [x] English / Spanish / System.
- [x] Privacy Manifest.

### 0.2 — TestFlight hardening

- [x] Edge-to-edge preview.
- [x] Safe-area controls.
- [x] Hidden shooting status bar.
- [x] AppIcon / launch appearance.
- [x] Required Reason API declaration.
- [x] Export-compliance declaration.
- [x] Release CI for Simulator and iPhoneOS.

### 0.3 — Pro capture + adaptive HUD

- [x] Portrait, landscape, and upside-down orientation policy.
- [x] AVFoundation RotationCoordinator.
- [x] Customizable safe-area HUD.
- [x] Optional Focus Peaking quick access.
- [x] HEVC-gated HEIF.
- [x] Maximum-resolution active formats.
- [x] `AVCapturePhotoOutput.maxPhotoDimensions`.
- [x] Per-shot `AVCapturePhotoSettings.maxPhotoDimensions`.
- [x] Capability-derived resolution selector including 12/24/48 MP where exposed.
- [x] Apple ProRAW capability path.
- [x] Capability-gated manual controls.
- [x] Improved physical lens labels/switching.
- [x] `scenePhase` recovery.
- [x] AVCaptureSession interruption/runtime-error observers.
- [x] Leading-line analysis.
- [x] Symmetry analysis.
- [x] Vanishing-point estimation.
- [x] Negative-space estimation.
- [x] Golden spiral overlay/guidance.
- [x] Golden triangle overlay/guidance.
- [x] General/Portrait/Architecture/Automotive/Macro/Street/Landscape/Night coach modes.

### 0.4 — Professional monitoring

- [x] Adjustable Zebra overlay.
- [x] Zebra range 75–100%.
- [x] Quick Zebra HUD control and presets.
- [x] RGB preview histogram.
- [x] Per-channel clipping indicators.
- [x] Expand/collapse histogram interaction.
- [x] Movable/hideable Zebra and Histogram HUD elements.
- [ ] Validate Zebra threshold accuracy on physical devices.
- [ ] Validate histogram alignment/performance in all orientations and lenses.

### Physical/release gates still open

- [ ] Validate 12/24/48 MP options and output dimensions on representative devices.
- [ ] Validate Bayer RAW and Apple ProRAW files on supported hardware.
- [ ] Validate HEIF output metadata/file type on supported hardware.
- [ ] Validate every physical lens and rotation.
- [ ] Validate session recovery after Settings/background/calls/camera interruption.
- [ ] Validate Focus Peaking alignment in every orientation.
- [ ] Validate geometric coach stability in varied real scenes.
- [ ] Validate Dynamic Island/notch/Home Indicator and large Dynamic Type.
- [ ] Product > Archive with a paid Developer Team.
- [ ] Organizer > Validate App.
- [ ] App Store Connect processing.
- [ ] Internal TestFlight smoke test.

### Future

- [ ] Bracketing.
- [ ] AF/AE lock gesture/control.
- [ ] Metadata inspection.
- [ ] Optional post-capture teaching review.
- [ ] Deterministic unit tests for coach decision logic.
- [ ] UI tests for settings/HUD persistence.

---

## Español

Un elemento marcado significa que existe implementación y que el proyecto compila. **No** significa que la función ya pasó aceptación física.

### 0.1 — Base

- [x] Preview/captura AVFoundation.
- [x] HEIF/JPEG.
- [x] Bayer RAW condicionado por hardware.
- [x] Lentes traseras físicas.
- [x] EV / ISO / obturación / enfoque / WB.
- [x] Tap-to-focus/medición.
- [x] Coach Vision/luminancia.
- [x] English / Español / Sistema.
- [x] Privacy Manifest.

### 0.2 — Hardening TestFlight

- [x] Preview edge-to-edge.
- [x] Controles dentro del área segura.
- [x] Barra de estado oculta.
- [x] AppIcon y launch.
- [x] Required Reason API.
- [x] Export compliance.
- [x] CI Release para Simulator/iPhoneOS.

### 0.3 — Captura Pro + HUD adaptativo

- [x] Vertical, horizontal y vertical invertido.
- [x] RotationCoordinator.
- [x] HUD personalizable.
- [x] Acceso Focus Peaking opcional.
- [x] HEIF condicionado a HEVC real.
- [x] Formato activo de máxima resolución.
- [x] `AVCapturePhotoOutput.maxPhotoDimensions`.
- [x] `AVCapturePhotoSettings.maxPhotoDimensions` por captura.
- [x] Resoluciones derivadas del hardware, incluyendo 12/24/48 MP donde estén expuestas.
- [x] Apple ProRAW condicionado por capability.
- [x] Controles manuales condicionados por capability.
- [x] Cambio/etiquetado de lentes mejorado.
- [x] Recuperación con `scenePhase`.
- [x] Observadores de interrupción/runtime error.
- [x] Líneas guía.
- [x] Simetría.
- [x] Punto de fuga.
- [x] Espacio negativo.
- [x] Espiral áurea.
- [x] Triángulo áureo.
- [x] Coaches General/Retrato/Arquitectura/Automotriz/Macro/Calle/Paisaje/Noche.

### 0.4 — Monitoreo profesional

- [x] Overlay de cebras ajustable.
- [x] Rango 75–100%.
- [x] Control rápido y presets de cebra.
- [x] Histograma RGB del preview.
- [x] Indicadores de clipping por canal.
- [x] Vista compacta/ampliada.
- [x] Zebra e Histograma movibles/ocultables en HUD.
- [ ] Validar umbral real de Zebra en hardware.
- [ ] Validar rendimiento/alineación del histograma en orientaciones/lentes.

### Gates pendientes

- [ ] Validar 12/24/48 MP y dimensiones de archivos en hardware.
- [ ] Validar Bayer RAW y ProRAW.
- [ ] Validar HEIF real.
- [ ] Validar lentes/orientaciones.
- [ ] Validar recuperación tras Settings/background/llamadas/interrupciones.
- [ ] Validar alineación Focus Peaking.
- [ ] Validar estabilidad del coach geométrico.
- [ ] Validar Dynamic Island/notch/Home Indicator/Dynamic Type.
- [ ] Archive firmado.
- [ ] Validate App.
- [ ] Procesamiento App Store Connect.
- [ ] Smoke test TestFlight interno.

### Futuro

- [ ] Bracketing.
- [ ] AF/AE Lock.
- [ ] Inspector de metadata.
- [ ] Revisión didáctica post-captura.
- [ ] Unit tests deterministas del coach.
- [ ] UI tests de HUD/ajustes.
