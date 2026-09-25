# Architecture / Arquitectura

## English

CapturePilot 0.7.0 separates capture, geometric analysis, Focus Peaking, HUD state, settings, and presentation.

### Capture pipeline

```text
AVCaptureDevice
      ↓
maximum-resolution active Format
      ↓
AVCapturePhotoOutput
  ├─ maxPhotoDimensions = active format maximum
  ├─ HEIF/HEVC when available
  ├─ JPEG
  ├─ Bayer RAW when available
  └─ Apple ProRAW when supported/enabled
      ↓
AVCapturePhotoSettings.maxPhotoDimensions
      ↓
Photos add-only save
```

The app selects the physical rear camera, then searches that device's formats for the highest `supportedMaxPhotoDimensions`. The output is configured with that maximum before normal capture. Per-shot resolution comes from the active format's valid dimension list.

This is capability-driven. CapturePilot does not synthesize a 48 MP option on hardware that does not expose one.

Apple ProRAW is enabled only after the output reports `isAppleProRAWSupported`. HEIF is exposed only when `availablePhotoCodecTypes` contains HEVC.

### RAW + Share JPEG pipeline

When enabled and capability-gated, CapturePilot creates one `AVCapturePhotoSettings` request containing a RAW pixel format plus a JPEG processed format. The request uses the active format's maximum valid `maxPhotoDimensions`.

`AVCapturePhotoCaptureDelegate` can receive both results from the same request. `AVCapturePhoto.isRawPhoto` separates the RAW result from the processed companion. The pair is accumulated by settings unique ID before post-processing.

Only the processed companion enters `RawShareProcessor`:

```text
processed companion → orientation → optional CIColorCube LUT
                    → optional intensity blend
                    → Lanczos downsample
                    → sRGB JPEG
```

The RAW data bypasses Core Image entirely.

Photos import first attempts JPEG `.photo` + RAW `.alternatePhoto`. A separate-assets fallback protects the capture if Photos rejects the pair.

See [RAW_SHARE_WORKFLOW.md](RAW_SHARE_WORKFLOW.md).

### LUT library and recommendation pipeline

CapturePilot 0.7 adds a persistent LUT-library layer without moving LUT analysis or image analysis off-device.

The photographer selects an external directory through the system Files picker. CapturePilot stores bookmark data for that directory and, on later launches, resolves the bookmark and starts security-scoped access before scanning.

`LUTLibraryStore` combines two sources:

- CapturePilot's local Documents/LUTs directory;
- the user-authorized external Files directory.

The external directory is enumerated recursively. Hidden files are skipped, supported 3D `.cube` files are parsed and profiled, and invalid files are counted rather than exposed as usable looks.

While the app is active, an `NSFilePresenter` observes the selected external folder. Changes schedule a debounced refresh. Returning to the foreground also reopens monitoring and refreshes the library.

Each valid LUT receives a deterministic transform profile containing:

- warmth;
- contrast;
- saturation;
- shadow lift;
- highlight compression;
- overall transform strength.

`LUTRecommendationEngine` ranks the available entries using that LUT profile together with the selected scene coach and current Coach exposure signals. It can return no recommendation when the scene has a more important capture problem or when candidates are weak/tied.

Recommendations are stabilized in `ContentView` and are never applied automatically. The photographer must explicitly apply the suggestion. Before capture, an external LUT is validated again and copied into CapturePilot's app-local active-LUT cache so the shutter path does not depend on a remote File Provider responding at capture time.

The RAW/ProRAW resource bypasses this LUT path. Only the Share JPEG can receive the active look.

See [LUT_LIBRARY.md](LUT_LIBRARY.md).

### Lens model

Rear cameras are discovered through `AVCaptureDevice.DiscoverySession`. Each physical device keeps its unique ID. The UI derives an approximate optical scale from field of view relative to the Wide camera, avoiding the old generic Tele label.

Switching lenses:

1. stops the running session briefly;
2. replaces the device input;
3. selects the best still-photo format for the new physical camera;
4. refreshes maximum dimensions, RAW/ProRAW/HEVC, and manual-control capabilities;
5. refreshes AVFoundation rotation coordination;
6. restarts the session if it was previously running.

### Manual controls

The service publishes capability flags for EV, custom exposure, locked focus, and locked white balance. `ManualControlsView` only renders controls that the active device can execute.

### Frame analysis

The single `AVCaptureVideoDataOutput` stream is shared by:

- `CoachEngine`;
- `FocusPeakingEngine`;
- `ProfessionalMonitoringEngine`.

`CoachEngine` throttles analysis to approximately one frame every 0.28 s and prevents overlapping analyses. It combines Vision requests with lightweight local luminance/geometry analysis.

Vision contributes face/person detection, horizon estimation, and attention-based saliency. The local analyzer samples preview luminance and downsamples geometry to a 64 × 48 grid, where it estimates vertical symmetry, edge/detail energy, strong Hough-style lines, leading-line strength, a possible vanishing point, and negative space.

The Coach does not turn these values into one aesthetic score. A deterministic priority tree first handles horizon/exposure problems, then applies scene-specific composition rules. A new primary recommendation must survive two consecutive analyzed frames before publication.

See [COACH.md](COACH.md) for current thresholds and decision branches.

These values are heuristics intended for coaching.

### Scene coaches

The selected scene mode changes recommendation priority, not the underlying truth of the image:

- General: broad balance.
- Portrait: person/headroom/thirds.
- Architecture: horizon/symmetry/vanishing geometry.
- Automotive: leading lines/negative space/subject placement.
- Macro: local detail plus golden-point placement.
- Street: leading lines/negative space/thirds.
- Landscape: horizon/golden-triangle/leading geometry.
- Night: exposure thresholds, highlights, stability, and lines.

### Golden geometry

The overlay supports thirds, golden ratio, golden spiral, golden triangle, crosshair, and level. Subject position is also compared with golden strong points so these modes can influence coaching rather than existing only as decorative lines.

### Orientation

The Info.plist advertises portrait, upside-down portrait, and both landscape orientations. `OrientationPolicy` applies the user's runtime restrictions.

`AVCaptureDevice.RotationCoordinator` independently updates preview and capture/video-output rotation.

### Session lifecycle

`ContentView` responds to SwiftUI `scenePhase`.

`CameraService` observes:

- `AVCaptureSession.wasInterruptedNotification`;
- `AVCaptureSession.interruptionEndedNotification`;
- `AVCaptureSession.runtimeErrorNotification`.

Camera authorization is rechecked on resume. A media-services reset triggers a recovery attempt.

### HUD

`HUDLayoutStore` persists visibility and normalized portrait/landscape coordinates for each HUD item. `HUDMovableItem` clamps the complete control to the safe rectangle.

The scene selector is a HUD item alongside Pro controls, language, lenses, coach, metrics, format, shutter, guide, Settings, and Focus Peaking.

### Privacy

No frame leaves the process in the current source. Coach analysis, Hough-style geometry, Vision, Focus Peaking, professional monitoring, LUT parsing/profiling, and LUT recommendations all run locally.

---

## Español

CapturePilot 0.7.0 separa captura, análisis geométrico, Focus Peaking, estado del HUD, ajustes y presentación.

### Pipeline de captura

```text
AVCaptureDevice
      ↓
Format de máxima resolución
      ↓
AVCapturePhotoOutput
  ├─ maxPhotoDimensions = máximo válido
  ├─ HEIF/HEVC si existe
  ├─ JPEG
  ├─ Bayer RAW si existe
  └─ Apple ProRAW si es compatible
      ↓
AVCapturePhotoSettings.maxPhotoDimensions
      ↓
Guardado add-only en Fotos
```

Para cada cámara física trasera se busca el formato con mayor `supportedMaxPhotoDimensions`. El máximo del output se configura con una dimensión válida del formato activo y cada disparo especifica explícitamente su dimensión.

CapturePilot no inventa una opción de 48 MP si el hardware/formato no la reporta.

ProRAW sólo se habilita cuando `isAppleProRAWSupported` lo permite. HEIF sólo aparece cuando HEVC está en `availablePhotoCodecTypes`.

### Pipeline RAW + JPEG

Cuando el modo está activo y las capabilities lo permiten, CapturePilot crea un único `AVCapturePhotoSettings` con RAW + JPEG processed y solicita las dimensiones máximas válidas del formato activo.

El delegate recibe ambos resultados del mismo request. `isRawPhoto` distingue RAW del companion procesado y ambos se agrupan por unique ID.

Sólo el JPEG pasa por `RawShareProcessor`: orientación, LUT opcional, intensidad, Lanczos y exportación sRGB. El RAW nunca entra al pipeline de LUT.

Fotos intenta JPEG `.photo` + RAW `.alternatePhoto`; existe fallback a assets separados.

Consulta [RAW_SHARE_WORKFLOW.md](RAW_SHARE_WORKFLOW.md).

### Biblioteca LUT y pipeline de recomendación

CapturePilot 0.7 agrega una capa de biblioteca LUT persistente sin sacar del dispositivo el análisis del LUT ni de la escena.

El fotógrafo selecciona una carpeta externa mediante el selector de Archivos. CapturePilot guarda bookmark data, resuelve ese bookmark en lanzamientos posteriores y abre acceso security-scoped antes de escanear.

`LUTLibraryStore` combina:

- Documents/LUTs local de CapturePilot;
- carpeta externa autorizada por el usuario.

La carpeta externa se recorre de forma recursiva. Se ignoran archivos ocultos, se validan LUT 3D `.cube` compatibles y los inválidos se cuentan sin presentarlos como looks utilizables.

Mientras la app está activa, `NSFilePresenter` observa cambios y programa un refresh con debounce. Al volver al foreground se reactiva el monitoreo y se actualiza la biblioteca.

Cada LUT válido recibe un perfil determinista de:

- calidez;
- contraste;
- saturación;
- levantamiento de sombras;
- compresión de luces;
- fuerza global de la transformación.

`LUTRecommendationEngine` combina ese perfil con el Coach de escena y señales actuales de exposición. Puede decidir no recomendar nada cuando existe un problema de captura prioritario o los candidatos son demasiado débiles/similares.

Las recomendaciones se estabilizan en `ContentView` y nunca se aplican automáticamente. El fotógrafo debe aceptar la sugerencia. Antes del disparo, un LUT externo se vuelve a validar y se copia al cache local activo para no depender de la respuesta de un File Provider en el momento de capturar.

El RAW/ProRAW no pasa por este pipeline; sólo el JPEG para compartir puede recibir el look.

Consulta [LUT_LIBRARY.md](LUT_LIBRARY.md).

### Lentes

Las cámaras traseras se descubren con `AVCaptureDevice.DiscoverySession` y conservan su ID físico. El factor aproximado de cada lente se calcula desde su campo de visión respecto al Wide.

Al cambiar de lente se reemplaza el input, se selecciona el mejor formato de foto, se recalculan resoluciones/RAW/ProRAW/HEVC/controles manuales, se renueva la coordinación de rotación y se reinicia la sesión si estaba activa.

### Controles manuales

El servicio publica capacidades reales para EV, exposición custom, focus locked y white balance locked. La UI sólo presenta controles que el dispositivo activo puede ejecutar.

### Análisis

Un único `AVCaptureVideoDataOutput` alimenta:

- `CoachEngine`;
- `FocusPeakingEngine`;
- `ProfessionalMonitoringEngine`.

`CoachEngine` limita el análisis a aproximadamente un frame cada 0.28 s y evita análisis simultáneos. Combina Vision con análisis local de luminancia/geometría.

Vision aporta rostro/persona, horizonte y saliencia. El análisis local muestrea luminancia y reduce la geometría a 64 × 48 para estimar simetría vertical, detalle/bordes, líneas tipo Hough, fuerza de líneas guía, posible punto de fuga y espacio negativo.

El Coach no convierte todo en un score estético. Primero prioriza problemas de horizonte/exposición y después aplica reglas compositivas por escena. Un mensaje nuevo debe mantenerse durante dos análisis consecutivos antes de publicarse.

Consulta [COACH.md](COACH.md) para los umbrales y ramas de decisión actuales.

Son heurísticas fotográficas, no mediciones infalibles.

### Coaches de escena

- General: equilibrio global.
- Retrato: persona/headroom/tercios.
- Arquitectura: horizonte/simetría/punto de fuga.
- Automotriz: líneas/espacio negativo/sujeto.
- Macro: detalle y puntos áureos.
- Calle: líneas/espacio negativo/tercios.
- Paisaje: horizonte/triángulo áureo/líneas.
- Noche: exposición, altas luces, estabilidad y geometría.

### Geometría áurea

El overlay incluye tercios, proporción áurea, espiral áurea, triángulo áureo, cruz y nivel. La posición del sujeto también se compara contra puntos áureos para que las guías tengan efecto sobre el coach.

### Orientación y ciclo de sesión

Info.plist permite vertical, vertical invertido y horizontal. `OrientationPolicy` aplica las preferencias.

`RotationCoordinator` actualiza preview y captura de forma independiente.

La vista responde a `scenePhase` y el servicio observa interrupción, fin de interrupción y runtime errors de `AVCaptureSession`. Al volver al foreground se vuelve a comprobar el permiso.

### HUD

`HUDLayoutStore` guarda visibilidad y coordenadas normalizadas separadas por orientación. Todos los elementos se mantienen dentro del área segura.

El selector de escena pasa a ser un elemento más del HUD.

### Privacidad

Los frames no salen del proceso. Vision, Coach, análisis geométrico, Focus Peaking, monitoreo profesional, parseo/perfilado de LUT y recomendaciones LUT funcionan localmente.
