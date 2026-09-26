# CapturePilot

**Professional photography, guided — not automated.**  
**Fotografía profesional, guiada — no automatizada.**

CapturePilot is a free, ad-free iOS camera that combines professional capture controls with an on-device photography coach. The coach prioritizes practical suggestions and does not assign an aesthetic score or replace the photographer's creative decisions.

CapturePilot es una cámara gratuita y sin anuncios para iOS que combina controles profesionales con un coach fotográfico local. El coach prioriza sugerencias prácticas; no asigna una puntuación estética ni sustituye las decisiones creativas del fotógrafo.

> **Current main / main actual: 0.8.0 (8).** Release compilation is verified in CI for both iOS Simulator and iPhoneOS. Physical-device testing, signed Archive validation, and App Store Connect processing remain release gates.

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

### RAW + Share JPEG

CapturePilot can now request RAW/ProRAW plus a processed JPEG from the same AVFoundation photo capture when the active camera configuration exposes RAW and approximately 48 MP-class maximum photo dimensions.

The RAW remains untouched. The processed companion can be exported as a 12/24/48 MP target JPEG, optionally using an imported 3D `.cube` LUT with adjustable intensity. CapturePilot never upscales the share copy.

The processed JPEG is available directly through the iOS Share Sheet after a successful save. Photos pairing is attempted as JPEG primary + RAW alternate, with a two-asset fallback.

See [RAW + Share JPEG](docs/RAW_SHARE_WORKFLOW.md) for capability rules and validation limits.

### LUT library and Coach recommendations

CapturePilot can use a user-selected Files folder as a persistent LUT library. After the photographer grants access once, CapturePilot bookmarks that directory, scans valid 3D `.cube` LUTs recursively, refreshes on folder changes/foreground, and combines those entries with its local LUT folder.

The Coach can optionally recommend one of the available LUTs in RAW+JPG mode. Recommendations are based on the LUT transform itself — warmth, contrast, saturation, shadow lift, highlight compression, and overall strength — plus the selected scene and current preview exposure signals. LUT filenames are not used as the decision model.

CapturePilot never applies a recommendation automatically. The photographer must explicitly accept it.

See [LUT library + Coach](docs/LUT_LIBRARY.md).

### Photo Rankings + Coach Review

CapturePilot 0.8 adds a private post-shot ranking section. New CapturePilot captures are analyzed automatically, and the photographer can also import selected images through the system Photos picker.

The section supports **Top 5 / 10 / 25 / 50**, category filters, per-photo Coach Score breakdowns, automatic category inference, and actionable suggestions for a stronger second attempt.

Coach Score is a **relative review aid**, not an objective artistic grade. It combines explainable CapturePilot exposure/composition/detail heuristics and, on supported OS versions, Apple's Vision aesthetics signal.

See [Photo Rankings + Coach Review](docs/RANKINGS.md).

### Friends + social scores

CapturePilot can optionally use the signed-in **iCloud account** to create a private random CapturePilot identity in CloudKit, derive an automatic `PILOT-...` username, and compare best CapturePilot-capture scores with accepted friends. CapturePilot never receives the visible Apple Account email or password.

0.8 synchronizes score metadata only — **not photos**. Imported images remain eligible for private local ranking but are excluded from social score submission.

See [Friends + social scores](docs/SOCIAL_COMPETITION.md).

### Professional controls

- EV compensation when supported.
- Auto/manual exposure.
- ISO and shutter duration.
- Auto/manual focus and lens position.
- Auto/manual white balance and color temperature.
- Unsupported manual controls are hidden instead of presenting controls that cannot work.
- Resolution selector in the Pro controls.

### Photography monitoring and capture aids

CapturePilot 0.5 adds still-photography monitoring tools to help evaluate a frame before capture:

- dual-level Zebra with configurable low/high thresholds;
- preview-derived False Color;
- RGB histogram with per-channel shadow/highlight clipping indicators;
- Luma Waveform;
- RGB Parade;
- Vectorscope;
- configurable Focus Peaking threshold and overlay color;
- compact per-channel clipping warnings;
- tap-to-focus/meter plus long-press AF/AE Lock when the active camera supports both locks;
- optional AF/AE Lock HUD control;
- photographic crop/frame guides: 1:1, 4:3, 3:2, 16:9, and 2.39:1.

Histogram, False Color, Waveform, RGB Parade, Vectorscope, and Zebras are derived from the processed live YCbCr preview. They are practical monitoring aids; CapturePilot does **not** describe them as sensor-linear RAW measurements, calibrated IRE instruments, or a replacement for inspecting the captured RAW/ProRAW file.

These are photography tools. CapturePilot does not add video codecs, bitrate, audio meters, or video-recording controls.

See [Professional monitoring](docs/MONITORING.md) for the signal path and limitations.

### Composition coach

All analysis is on-device. The Coach is deterministic and explainable: it combines Vision, sampled luminance, and geometric heuristics, then applies a scene-specific priority tree. It does not produce an aesthetic score.

See [Coach system](docs/COACH.md) for the current signal pipeline, thresholds, scene priorities, stabilization behavior, and validation limits.

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
- Optional Zebra, Histogram, False Color, Waveform, RGB Parade, Vectorscope, AF/AE Lock, clipping-warning, and frame-guide controls.
- Settings and shutter remain non-hideable recovery controls.

### Focus Peaking

Focus Peaking uses the luminance plane already delivered by the camera pipeline and highlights strong local edges. It is a contrast-based focusing aid, not an absolute focus-confidence measurement.

The photographer can change the Peaking threshold and overlay color. The optional quick-access button remains separate from viewfinder long-press, which is reserved for AF/AE Lock.

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
- Coach, geometry analysis, Focus Peaking, Zebras, histogram, False Color, Waveform, RGB Parade, Vectorscope, LUT parsing/profiling, and LUT recommendations run on-device.
- External LUT folders are read only after the photographer explicitly selects one through the system Files picker.
- Privacy Manifest declares no tracking or collected-data types.
- UserDefaults Required Reason API: CA92.1.

### Build / release status

- Minimum deployment target: iOS 17.
- Current version/build: **0.8.0 (8)**.
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

### RAW + JPEG para compartir

CapturePilot puede solicitar RAW/ProRAW y un JPEG procesado desde el mismo disparo AVFoundation cuando la cámara activa expone RAW y dimensiones máximas de clase aproximada 48 MP.

El RAW permanece intacto. El companion procesado puede exportarse con objetivo 12/24/48 MP y un LUT 3D `.cube` opcional con intensidad ajustable. CapturePilot nunca hace upscale del JPEG.

Después de guardar, el JPEG queda disponible directamente en Share Sheet. Fotos intenta conservar JPEG principal + RAW alternativo; si no acepta la combinación, se guardan dos assets.

Consulta [RAW + JPEG para compartir](docs/RAW_SHARE_WORKFLOW.md).

### Biblioteca LUT y recomendaciones del Coach

CapturePilot puede usar una carpeta elegida en Archivos como biblioteca LUT persistente. Después de conceder acceso una vez, la app conserva un bookmark, escanea recursivamente LUT 3D `.cube` válidos, actualiza la biblioteca cuando cambia la carpeta o al volver al foreground y combina esos LUT con la carpeta local de CapturePilot.

El Coach puede recomendar opcionalmente un LUT disponible en RAW+JPG. La recomendación usa el transform real del LUT —calidez, contraste, saturación, sombras, luces y fuerza— junto con la escena seleccionada y señales actuales de exposición. El nombre del archivo no decide la recomendación.

CapturePilot nunca aplica el LUT automáticamente; el fotógrafo debe aceptarlo explícitamente.

Consulta [Biblioteca LUT + Coach](docs/LUT_LIBRARY.md).

### Ranking de fotos + revisión del Coach

CapturePilot 0.8 agrega una sección privada de análisis posterior al disparo. Las nuevas capturas se analizan automáticamente y también pueden importarse imágenes seleccionadas mediante el selector de Fotos.

Permite **Top 5 / 10 / 25 / 50**, filtros por categoría, desglose del Coach Score, clasificación automática y recomendaciones concretas para mejorar o explorar una segunda toma.

Coach Score es una **ayuda de comparación relativa**, no una calificación objetiva del valor artístico.

Consulta [Ranking + Coach Review](docs/RANKINGS.md).

### Amigos + scores sociales

Opcionalmente CapturePilot usa la **cuenta iCloud** iniciada en el dispositivo para crear una identidad privada aleatoria en CloudKit, derivar un username automático `PILOT-...` y comparar mejores scores con amigos aceptados. CapturePilot no recibe el correo visible ni la contraseña de la cuenta Apple.

0.8 sincroniza sólo metadata de score, **no fotografías**. Las imágenes importadas participan en el ranking local pero no pueden subir score social.

Consulta [Amigos + scores sociales](docs/SOCIAL_COMPETITION.md).

### Controles profesionales

- Compensación EV cuando está disponible.
- Exposición automática/manual.
- ISO y obturación.
- Enfoque automático/manual y posición de lente.
- Balance de blancos automático/manual y temperatura.
- Los controles manuales no compatibles se ocultan en lugar de presentar funciones inactivas.
- Selector de resolución dentro de los controles Pro.

### Monitoreo y ayudas de captura fotográfica

CapturePilot 0.5 agrega herramientas para evaluar la fotografía antes de capturar:

- Zebra dual con umbrales bajo/alto configurables;
- False Color derivado del preview;
- histograma RGB con avisos de clipping por canal;
- Waveform Luma;
- RGB Parade;
- Vectorscope;
- umbral y color configurables de Focus Peaking;
- avisos compactos de clipping por canal;
- toque para enfoque/medición y pulsación larga para AF/AE Lock cuando la cámara activa soporta ambos bloqueos;
- botón HUD opcional para AF/AE Lock;
- guías de formato/recorte: 1:1, 4:3, 3:2, 16:9 y 2.39:1.

Histograma, False Color, Waveform, RGB Parade, Vectorscope y Cebras se derivan del preview YCbCr procesado. Son ayudas prácticas de monitoreo; CapturePilot **no** las presenta como mediciones RAW lineales del sensor, instrumentos IRE calibrados ni sustitutos de revisar el RAW/ProRAW capturado.

Son herramientas de fotografía. CapturePilot no agrega codecs, bitrate, medidores de audio ni controles de grabación de video.

Consulta [Monitoreo profesional](docs/MONITORING.md) para conocer la ruta de señal y sus límites.

### Coach de composición

Todo el análisis ocurre en el dispositivo. El Coach es determinista y explicable: combina Vision, luminancia muestreada y heurísticas geométricas, y después aplica una jerarquía de prioridades según la escena. No genera un score estético.

Consulta [Sistema del Coach](docs/COACH.md) para ver el pipeline actual, umbrales, prioridades por escena, estabilización y límites de validación.

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
- Controles opcionales para Zebra, Histograma, False Color, Waveform, RGB Parade, Vectorscope, AF/AE Lock, clipping y guía de formato.
- Ajustes y disparador no pueden ocultarse.

### Focus Peaking

Focus Peaking analiza contraste local en el plano de luminancia del mismo pipeline de cámara. Es una ayuda visual de enfoque, no una medición absoluta del plano focal.

El fotógrafo puede cambiar el umbral y el color del overlay. El botón rápido opcional permanece separado de la pulsación larga del visor, reservada para AF/AE Lock.

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
- Coach, geometría, Focus Peaking, Cebras, histograma, False Color, Waveform, RGB Parade, Vectorscope, parseo/perfilado LUT y recomendaciones LUT son locales.
- Las carpetas LUT externas sólo se leen después de que el fotógrafo seleccione una explícitamente mediante el selector de Archivos.
- Privacy Manifest sin tracking ni tipos de datos recopilados.
- Required Reason API de UserDefaults: CA92.1.

### Build / estado de publicación

- iOS 17 mínimo.
- Versión/build actual: **0.8.0 (8)**.
- GitHub Actions compila Release para Simulator e iPhoneOS.
- Cámara física, disponibilidad real 12/24/48 MP, RAW/ProRAW, Dynamic Island/notch, orientación y sensores todavía requieren aceptación en dispositivo.
- TestFlight sólo se considera validado después de Archive firmado + Validate App + procesamiento correcto en App Store Connect.

## Documentation / Documentación

- [Architecture / Arquitectura](docs/ARCHITECTURE.md)
- [Coach / Coach](docs/COACH.md)
- [RAW + Share JPEG / RAW + JPEG](docs/RAW_SHARE_WORKFLOW.md)
- [LUT library + Coach / Biblioteca LUT + Coach](docs/LUT_LIBRARY.md)
- [Photo Rankings / Ranking de fotos](docs/RANKINGS.md)
- [Friends + social scores / Amigos + scores sociales](docs/SOCIAL_COMPETITION.md)
- [Roadmap / Hoja de ruta](docs/ROADMAP.md)
- [Device testing / Pruebas físicas](docs/TESTING.md)
- [UI layout / Pantalla completa](docs/UI_LAYOUT.md)
- [TestFlight](docs/TESTFLIGHT.md)
- [Privacy / Privacidad](docs/PRIVACY.md)
- [App Store metadata](docs/APP_STORE_METADATA.md)
- [Changelog / Registro de cambios](CHANGELOG.md)

## Technology

SwiftUI · AVFoundation · Vision · Photos · Core Video · Core Image · Files / security-scoped access

## License / Licencia

CapturePilot is released under the [MIT License](LICENSE). / CapturePilot se publica bajo la [Licencia MIT](LICENSE).
