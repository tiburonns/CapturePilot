# Changelog / Registro de cambios

## 0.3.0 — Pro capture, geometry coaching, orientation and HUD

### English

#### Added

- Capability-gated HEIF/HEVC, Bayer RAW, and Apple ProRAW paths.
- Maximum-resolution active-format selection.
- `AVCapturePhotoOutput.maxPhotoDimensions` configuration.
- Explicit per-shot `AVCapturePhotoSettings.maxPhotoDimensions`.
- Hardware-derived resolution menu, including 12/24/48 MP where supported.
- Improved physical-lens discovery, unique IDs, and field-of-view-derived labels.
- Manual-control capability gating.
- Leading-line, symmetry, vanishing-point, negative-space, and detail analysis.
- Golden spiral and golden triangle overlays/guidance.
- General, Portrait, Architecture, Automotive, Macro, Street, Landscape, and Night coaches.
- `scenePhase` session recovery.
- AVCaptureSession interruption/end/runtime-error handling.
- Landscape and upside-down orientation policy.
- Customizable safe-area HUD with independent portrait/landscape layouts.
- Optional Focus Peaking quick-access control.

#### Changed

- HEIF no longer silently falls back to JPEG while still presenting itself as HEIF.
- Lens changes refresh capture resolution, codecs, RAW/ProRAW, manual-control capabilities, and rotation.
- Pro controls hide unsupported hardware controls.
- Version/build is 0.3.0 (3).

#### Validation

- Release compiles in GitHub Actions for iOS Simulator and iPhoneOS.
- Physical-device and App Store/TestFlight acceptance remain separate gates.

### Español

#### Agregado

- HEIF/HEVC, Bayer RAW y Apple ProRAW condicionados por capabilities.
- Selección del formato activo de máxima resolución.
- Configuración de `AVCapturePhotoOutput.maxPhotoDimensions`.
- `AVCapturePhotoSettings.maxPhotoDimensions` explícito por captura.
- Resoluciones derivadas del hardware, incluyendo 12/24/48 MP cuando existen.
- Descubrimiento/etiquetado mejorado de lentes físicas.
- Controles manuales condicionados por capability.
- Líneas, simetría, punto de fuga, espacio negativo y detalle.
- Espiral y triángulo áureos.
- Coaches General, Retrato, Arquitectura, Automotriz, Macro, Calle, Paisaje y Noche.
- Recuperación mediante `scenePhase`.
- Interrupciones/runtime errors de AVCaptureSession.
- Horizontal y vertical invertido.
- HUD personalizable por orientación.
- Acceso opcional a Focus Peaking.

#### Cambios

- HEIF ya no cae silenciosamente a JPEG manteniendo la etiqueta HEIF.
- Cambiar de lente recalcula resolución, codecs, RAW/ProRAW, controles y rotación.
- Los controles Pro no soportados se ocultan.
- Versión/build 0.3.0 (3).

#### Validación

- Release compila en CI para Simulator e iPhoneOS.
- Hardware y TestFlight/App Store siguen como gates separados.

## 0.2.0 — TestFlight candidate hardening / Hardening TestFlight

- Direct System / English / Spanish language menu.
- Safe-area-aware full-screen camera chrome.
- AppIcon and launch resources.
- Privacy/Required Reason/export-compliance hardening.
- Release-build CI workflow.

## 0.1.0 — Initial camera baseline / Base inicial

- AVFoundation camera.
- HEIF/JPEG and capability-gated RAW.
- Rear lens switching.
- Tap-to-focus/meter.
- EV/ISO/shutter/manual focus/white balance.
- Vision/luminance coach.
- Thirds/golden-ratio/crosshair/level.
- English/Spanish/System.
