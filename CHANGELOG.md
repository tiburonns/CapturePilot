# Changelog / Registro de cambios

## 0.8.0 — Rankings + friends / Ranking + amigos

### English
- New private Rankings section.
- Automatic analysis of CapturePilot captures.
- PhotosPicker import for selected existing photos.
- Top 5 / 10 / 25 / 50.
- Category filtering: General, Portrait, Architecture, Automotive, Macro, Street, Landscape, Night.
- Coach Score with exposure/composition/detail signals.
- Vision aesthetics signal on supported OS versions with iOS 17 fallback.
- Portrait face-capture quality contribution when available.
- Per-photo Coach recommendations.
- Local thumbnail/index persistence and duplicate fingerprinting.
- Optional private iCloud-backed social identity.
- Automatic Pilot-* username.
- CloudKit friend requests and accepted friends list.
- Overall/category friend leaderboard.
- Opt-in best-score sharing.
- Only CapturePilot captures can contribute social scores.
- No social photo upload in 0.8.
- Version/build 0.8.0 (8).

### Español
- Nueva sección privada Ranking.
- Análisis automático de capturas.
- Importación PhotosPicker.
- Top 5 / 10 / 25 / 50.
- Filtros General/Retrato/Arquitectura/Automotriz/Macro/Calle/Paisaje/Noche.
- Coach Score con exposición/composición/detalle.
- Señal estética Vision en sistemas compatibles y fallback iOS 17.
- Calidad de captura facial para Retrato cuando está disponible.
- Recomendaciones por fotografía.
- Miniaturas/índice local y fingerprint de duplicados.
- Identidad social privada respaldada por iCloud opcional.
- Username Pilot-* automático.
- Solicitudes/amigos mediante CloudKit.
- Ranking social Overall/categorías.
- Compartir mejores scores opt-in.
- Sólo capturas CapturePilot aportan score social.
- Sin fotos sociales en 0.8.
- Versión/build 0.8.0 (8).

## 0.7.0 — LUT library + Coach recommendations / Biblioteca LUT + recomendaciones del Coach

### English
- Persistent user-selected LUT folder from Files.
- Recursive discovery of valid 3D .cube LUTs.
- Folder monitoring while CapturePilot is active.
- Foreground refresh and manual rescan.
- Combined local + external LUT library.
- Invalid LUT counting.
- Deterministic LUT profiling: warmth, contrast, saturation, shadow lift, highlight compression, strength.
- Scene/exposure-aware Coach LUT recommendations.
- Stabilized recommendation UI.
- Explicit Apply action; no automatic LUT changes.
- Active external LUT is validated and cached locally before capture.
- Version/build 0.7.0 (7).

### Español
- Carpeta LUT persistente seleccionada en Archivos.
- Descubrimiento recursivo de LUT 3D .cube válidos.
- Monitoreo de carpeta mientras CapturePilot está activo.
- Refresh al volver al foreground y rescan manual.
- Biblioteca local + externa.
- Conteo de LUT inválidos.
- Perfil determinista de calidez, contraste, saturación, sombras, luces y fuerza.
- Recomendaciones del Coach según escena/exposición.
- UI de recomendación estabilizada.
- Aplicación explícita; no hay cambios automáticos de LUT.
- LUT externo validado y cacheado localmente antes de capturar.
- Versión/build 0.7.0 (7).

## 0.6.0 — RAW + Share JPEG / RAW + JPEG para compartir

### English
- Single-request RAW/ProRAW + processed JPEG workflow.
- Capability gate for approximately 48 MP-class RAW capture configurations.
- Share JPEG targets: 12/24/48 MP, never upscaled.
- 3D .cube LUT import from Files.
- Adjustable LUT intensity.
- Core Image CIColorCube processing.
- High-quality Lanczos downsample.
- sRGB JPEG at 0.94 quality.
- Quick Share Sheet access after capture.
- JPEG primary + RAW alternate Photos import attempt.
- Separate-assets fallback.
- Version/build 0.6.0 (6).

### Español
- Flujo RAW/ProRAW + JPEG procesado en un único request.
- Capability gate para configuraciones RAW de clase aproximada 48 MP.
- JPEG 12/24/48 MP sin upscale.
- Importación LUT 3D .cube desde Files.
- Intensidad ajustable.
- Procesamiento CIColorCube.
- Downsample Lanczos.
- JPEG sRGB calidad 0.94.
- Share Sheet rápido.
- Intento JPEG principal + RAW alternativo.
- Fallback a assets separados.
- Versión/build 0.6.0 (6).

## 0.5.0 — Photography scopes and capture aids / Scopes y ayudas fotográficas

### English
- Preview-derived False Color.
- Luma Waveform, RGB Parade, and Vectorscope.
- Long-press AF/AE Lock plus optional HUD lock control.
- Configurable Focus Peaking threshold and color.
- Dual-level Zebra with independent low/high thresholds.
- Compact per-channel clipping warnings.
- Frame guides for 1:1, 4:3, 3:2, 16:9, and 2.39:1.
- All new tools integrate with the movable/hideable HUD.
- No video recording parameters were added.
- Version/build 0.5.0 (5).

### Español
- False Color derivado del preview.
- Waveform Luma, RGB Parade y Vectorscope.
- AF/AE Lock por pulsación larga y botón HUD opcional.
- Umbral/color configurables de Focus Peaking.
- Zebra dual con umbral bajo/alto.
- Avisos compactos de clipping por canal.
- Guías 1:1, 4:3, 3:2, 16:9 y 2.39:1.
- Todas las herramientas se integran al HUD movible/ocultable.
- No se agregaron parámetros de grabación de video.
- Versión/build 0.5.0 (5).

## 0.4.0 — Professional monitoring / Monitoreo profesional

### English
- Adjustable Zebra overlay with 75–100% threshold.
- HUD Zebra quick toggle plus exposure-level presets.
- RGB histogram derived from the live YCbCr preview stream.
- Per-channel highlight/shadow clipping indicators.
- Tap-to-expand histogram.
- Zebra and Histogram integrated into the movable/hideable HUD.
- Monitoring work is gated so hidden/inactive tools do not continuously process frames.
- Version/build 0.4.0 (4).

### Español
- Cebras ajustables entre 75–100%.
- Control rápido HUD y presets de exposición.
- Histograma RGB derivado del preview YCbCr.
- Indicadores de clipping por canal.
- Histograma ampliable con un toque.
- Zebra e Histograma integrados al HUD movible/ocultable.
- El procesamiento se detiene cuando las herramientas no están activas/visibles.
- Versión/build 0.4.0 (4).

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
