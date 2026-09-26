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

### 0.5 — Photography scopes + capture aids

- [x] Preview-derived False Color.
- [x] Luma Waveform.
- [x] RGB Parade.
- [x] Vectorscope.
- [x] Configurable Focus Peaking threshold/color.
- [x] Dual-level Zebra.
- [x] Per-channel clipping-warning HUD.
- [x] Long-press AF/AE Lock.
- [x] Optional AF/AE Lock HUD control.
- [x] Frame guides: 1:1, 4:3, 3:2, 16:9, 2.39:1.
- [ ] Validate scope behavior against controlled test charts/scenes.
- [ ] Validate AF/AE lock timing and recovery on physical hardware.
- [ ] Validate combined scopes/coach thermal performance.

### 0.6 — RAW + Share JPEG

- [x] Single-request RAW/ProRAW + processed JPEG capture path.
- [x] Maximum-dimension RAW-share request.
- [x] 12/24/48 MP Share JPEG targets with no upscaling.
- [x] 3D .cube LUT import.
- [x] LUT intensity.
- [x] Core Image LUT processing.
- [x] Lanczos JPEG downsample.
- [x] Quick iOS Share Sheet URL.
- [x] JPEG-primary + RAW-alternate Photos import attempt.
- [x] Separate-assets fallback.
- [ ] Verify 48 MP RAW/ProRAW dimensions on physical hardware.
- [ ] Verify processed-companion dimensions.
- [ ] Validate LUT output against references.
- [ ] Validate Photos RAW/JPEG pairing and metadata.
- [ ] Validate memory/thermal performance at maximum resolution.

### 0.7 — LUT library + Coach recommendations

- [x] User-selected Files LUT folder.
- [x] Persistent folder bookmark.
- [x] Recursive .cube discovery.
- [x] Folder change monitoring while active.
- [x] Refresh on foreground and manual rescan.
- [x] Local + external LUT library.
- [x] Invalid-LUT counting.
- [x] LUT transform profiling: warmth/contrast/saturation/shadows/highlights/strength.
- [x] Scene + exposure-aware LUT recommendation.
- [x] Recommendation stabilization.
- [x] Explicit user apply action; no automatic look changes.
- [x] Active LUT copied into CapturePilot cache before capture.
- [ ] Validate persistent folder access across relaunch/reboot.
- [ ] Validate iCloud Drive and third-party File Provider behavior.
- [ ] Validate live change detection for add/remove/rename.
- [ ] Validate LUT profile/recommendation sanity against known references.
- [ ] Validate large LUT libraries and 65³ cubes.

### 0.8 — Rankings + friends scores

- [x] Automatic post-shot analysis for CapturePilot captures.
- [x] PhotosPicker import without full-library browsing.
- [x] Top 5 / 10 / 25 / 50.
- [x] Category filters.
- [x] Automatic category inference with scene-mode fallback.
- [x] Coach Score breakdown.
- [x] Vision aesthetics signal on supported OS versions.
- [x] iOS 17 scoring fallback.
- [x] Per-photo improvement/interest recommendations.
- [x] Private local thumbnail/index persistence.
- [x] Sign in with Apple identity layer.
- [x] Automatic Pilot-* username.
- [x] Friend requests/accept/remove.
- [x] Friends leaderboard by category.
- [x] Opt-in best-score sharing.
- [x] Imported images excluded from social score submission.
- [x] No social photo upload in 0.8.
- [ ] Validate ranking with a diverse real-world photo set.
- [ ] Validate RAW/ProRAW post-shot decoding/ranking.
- [ ] Configure Sign in with Apple + CloudKit resources in Apple Developer.
- [ ] Create/verify CloudKit development schema and queryable indexes.
- [ ] Deploy CloudKit schema for distribution.
- [ ] Validate social flow with two real Apple accounts/devices.
- [ ] Validate credential revocation.
- [ ] Evaluate trusted server-side score validation before any prize/high-stakes competition.
- [ ] Add moderation/report/block infrastructure before any future social photo sharing.

### Physical/release gates still open

- [ ] Validate 12/24/48 MP options and output dimensions on representative devices.
- [ ] Validate Bayer RAW and Apple ProRAW files on supported hardware.
- [ ] Validate HEIF output metadata/file type on supported hardware.
- [ ] Validate every physical lens and rotation.
- [ ] Validate session recovery after Settings/background/calls/camera interruption.
- [ ] Validate Focus Peaking alignment in every orientation.
- [ ] Validate geometric Coach stability and false-positive rate in varied real scenes.
- [ ] Validate current Coach thresholds against controlled horizon/exposure/composition scenes.
- [ ] Validate Dynamic Island/notch/Home Indicator and large Dynamic Type.
- [ ] Product > Archive with a paid Developer Team.
- [ ] Organizer > Validate App.
- [ ] App Store Connect processing.
- [ ] Internal TestFlight smoke test.

### Future

- [ ] Bracketing.
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

### 0.5 — Scopes fotográficos + ayudas de captura

- [x] False Color derivado del preview.
- [x] Waveform Luma.
- [x] RGB Parade.
- [x] Vectorscope.
- [x] Umbral/color configurables de Focus Peaking.
- [x] Zebra dual.
- [x] Avisos de clipping por canal.
- [x] AF/AE Lock por pulsación larga.
- [x] Botón HUD opcional AF/AE.
- [x] Guías 1:1, 4:3, 3:2, 16:9, 2.39:1.
- [ ] Validar scopes con cartas/escenas controladas.
- [ ] Validar timing/recuperación de AF/AE Lock en hardware.
- [ ] Validar carga térmica usando scopes + coach.

### 0.6 — RAW + JPEG para compartir

- [x] RAW/ProRAW + JPEG processed en un único request.
- [x] Request a máxima dimensión.
- [x] JPEG objetivo 12/24/48 MP sin upscale.
- [x] Importación LUT 3D .cube.
- [x] Intensidad del LUT.
- [x] Procesamiento Core Image.
- [x] Downsample Lanczos.
- [x] Share Sheet rápido.
- [x] Intento JPEG principal + RAW alternativo en Fotos.
- [x] Fallback a assets separados.
- [ ] Verificar dimensiones RAW/ProRAW 48 MP en hardware.
- [ ] Verificar dimensiones del companion procesado.
- [ ] Validar LUT contra referencias.
- [ ] Validar pairing/metadata en Fotos.
- [ ] Validar memoria/temperatura a máxima resolución.

### 0.7 — Biblioteca LUT + recomendaciones del Coach

- [x] Carpeta LUT seleccionada por el usuario en Archivos.
- [x] Bookmark persistente.
- [x] Descubrimiento recursivo .cube.
- [x] Monitoreo de cambios mientras la app está activa.
- [x] Refresh al volver al foreground y rescan manual.
- [x] Biblioteca LUT local + externa.
- [x] Conteo de LUT inválidos.
- [x] Perfil de calidez/contraste/saturación/sombras/luces/fuerza.
- [x] Recomendación según escena + exposición.
- [x] Estabilización de recomendaciones.
- [x] Aplicación explícita; nunca automática.
- [x] LUT activo copiado al cache local antes de capturar.
- [ ] Validar acceso persistente tras relanzar/reiniciar.
- [ ] Validar iCloud Drive y File Providers de terceros.
- [ ] Validar altas/bajas/renombres en vivo.
- [ ] Validar perfiles/recomendaciones contra LUT conocidos.
- [ ] Validar bibliotecas grandes y cubos 65³.

### 0.8 — Ranking + scores con amigos

- [x] Análisis automático post-shot.
- [x] Importación PhotosPicker.
- [x] Top 5 / 10 / 25 / 50.
- [x] Filtros por categoría.
- [x] Clasificación automática con fallback de escena.
- [x] Desglose Coach Score.
- [x] Señal estética Vision cuando está disponible.
- [x] Fallback iOS 17.
- [x] Recomendaciones por foto.
- [x] Índice/miniaturas privadas locales.
- [x] Sign in with Apple.
- [x] Username Pilot-* automático.
- [x] Solicitudes/aceptación/eliminación de amigos.
- [x] Ranking de amigos por categoría.
- [x] Compartir mejores scores opcional.
- [x] Importaciones excluidas del score social.
- [x] Sin subida social de fotos en 0.8.
- [ ] Validar ranking con fotos reales diversas.
- [ ] Validar RAW/ProRAW.
- [ ] Configurar Sign in with Apple + CloudKit en Apple Developer.
- [ ] Crear/verificar schema e índices CloudKit.
- [ ] Desplegar schema para distribución.
- [ ] Probar con dos cuentas/dispositivos.
- [ ] Probar revocación de credenciales.
- [ ] Evaluar validación confiable antes de competencias con premios.
- [ ] Añadir moderación/report/block antes de compartir fotos socialmente.

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
- [ ] Inspector de metadata.
- [ ] Revisión didáctica post-captura.
- [ ] Unit tests deterministas del coach.
- [ ] UI tests de HUD/ajustes.
