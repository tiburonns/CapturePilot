# LUT Library + Coach Recommendations / Biblioteca LUT + recomendaciones del Coach

CapturePilot 0.7 adds a persistent LUT library built around a user-selected Files folder plus explainable, on-device LUT recommendations from the Coach.

## English

### Folder access model

iOS does not let CapturePilot scan arbitrary Files locations without user consent.

The workflow is:

1. the photographer chooses a LUT folder with the system document picker;
2. iOS returns a security-scoped directory URL;
3. CapturePilot stores bookmark data for that directory;
4. on later launches CapturePilot resolves the bookmark and reopens the directory;
5. the app recursively enumerates `.cube` files in that folder and its subfolders.

Apple documents that a directory selected through `UIDocumentPickerViewController` can provide recursive access to the directory and future items added there, and that the URL can be bookmarked for later launches.

### Automatic detection

While CapturePilot is active:
- an `NSFilePresenter` watches the selected folder;
- file changes schedule a debounced rescan;
- app foregrounding also restarts monitoring and refreshes the library;
- an explicit **Rescan LUTs** control remains available.

The scanner:
- ignores hidden files;
- scans subfolders recursively;
- accepts only valid 3D `.cube` files supported by CapturePilot;
- counts invalid LUT files instead of presenting them as usable looks.

### Local CapturePilot LUT folder

CapturePilot also scans its own local Documents/LUTs folder.

The combined library can therefore contain:
- CapturePilot-local LUTs;
- LUTs from the user-selected Files folder.

### LUT profile

CapturePilot does not recommend a LUT from its filename.

Each valid cube is sampled and given a lightweight deterministic profile:

- **warmth** — red/blue balance around mid gray;
- **contrast** — tonal separation between dark and bright neutral probes;
- **saturation** — chroma change on red/green/blue probes;
- **shadow lift** — how much the LUT raises or lowers dark neutrals;
- **highlight compression** — whether bright neutrals are compressed;
- **strength** — average distance from an identity transform across several probes.

These are heuristics describing the LUT transform. They are not a color-science certification or a claim about artistic quality.

### Coach recommendation

A recommendation is considered only when:
- RAW+JPG is enabled;
- LUT Coach recommendations are enabled;
- Coach intensity is Balanced or Teaching;
- at least one valid LUT exists.

The recommendation engine combines:
- selected scene mode;
- current preview average luminance;
- highlight clipping ratio;
- shadow clipping ratio;
- the profile of every available LUT.

The engine intentionally refuses to recommend a LUT when capture conditions are already severely compromised, for example heavy highlight clipping or a frame that is too dark. Capture correction remains more important than a look.

### Scene tendencies

Current scoring tendencies are:

| Scene | Preferred transform tendencies |
| --- | --- |
| Portrait | moderate warmth, restrained contrast/saturation |
| Architecture | more contrast, neutral color bias |
| Automotive | contrast + saturation |
| Macro | saturation + local tonal separation |
| Street | contrast, restrained saturation |
| Landscape | saturation + contrast + some highlight compression |
| Night | shadow lift + highlight compression, restrained contrast |
| General | conservative transform close to neutral |

Exposure conditions can override the scene tendency. For example, mild highlight pressure favors LUTs that compress highlights.

### Confidence and stabilization

The engine ranks all valid LUTs and compares the best candidate with the runner-up.

It can return no recommendation when the candidates are effectively tied and weak.

Recommendation confidence is capped below 1.0 because the result is heuristic.

The UI also stabilizes LUT suggestions across repeated Coach updates before replacing the visible suggestion, reducing visual churn.

### User control

CapturePilot never applies a recommended LUT automatically.

The Coach displays:
- **Recommended LUT / LUT recomendado**;
- LUT name;
- a short reason;
- an explicit apply button.

The photographer must choose to apply it.

When applied, the LUT is validated again and copied to CapturePilot's local active-LUT cache before capture. The RAW file remains untouched; only the Share JPEG uses the selected LUT.

### Privacy

Folder enumeration, LUT parsing, profiling, recommendation, and application all happen on-device.

No LUT file, LUT profile, preview frame, or recommendation is uploaded to a CapturePilot service.

### Validation gates

Physical/device acceptance still needs:
- Files folder on device storage;
- iCloud Drive folder;
- at least one third-party File Provider folder where available;
- add/remove/rename LUT while CapturePilot is active;
- add LUT while CapturePilot is backgrounded then return;
- bookmark persistence across relaunch/reboot;
- stale/moved folder handling;
- nested subfolder discovery;
- large LUT collections;
- 17³ / 33³ / 65³ cubes;
- invalid-file counting;
- recommendation stability across real scenes;
- LUT profile sanity checks against known reference transforms.

---

## Español

CapturePilot 0.7 agrega una biblioteca LUT persistente basada en una carpeta seleccionada por el usuario en Archivos y recomendaciones explicables del Coach.

### Acceso a la carpeta

iOS no permite que CapturePilot escanee libremente cualquier ubicación de Archivos.

El flujo es:

1. el fotógrafo selecciona una carpeta LUT mediante el selector del sistema;
2. iOS entrega una URL de directorio con acceso security-scoped;
3. CapturePilot guarda bookmark data para esa carpeta;
4. en lanzamientos posteriores resuelve el bookmark;
5. enumera recursivamente los archivos `.cube` de la carpeta y subcarpetas.

### Detección automática

Mientras CapturePilot está activo:
- `NSFilePresenter` observa cambios;
- un cambio programa un rescan con debounce;
- volver al foreground reactiva monitoreo y actualización;
- existe además **Reescanear LUTs** manual.

El scanner:
- ignora archivos ocultos;
- recorre subcarpetas;
- sólo muestra LUT 3D válidos;
- cuenta LUT inválidos sin ofrecerlos como looks utilizables.

### Biblioteca combinada

CapturePilot también escanea su carpeta local Documents/LUTs.

La biblioteca puede combinar:
- LUT locales de CapturePilot;
- LUT de la carpeta externa seleccionada en Archivos.

### Perfilado de LUT

La recomendación no depende del nombre del archivo.

Cada LUT se muestrea para estimar:
- calidez;
- contraste;
- saturación;
- levantamiento de sombras;
- compresión de luces;
- fuerza general de la transformación.

Son heurísticas del transform, no una certificación colorimétrica ni una medida de calidad artística.

### Recomendación del Coach

Se considera una recomendación cuando:
- RAW+JPG está activo;
- recomendaciones LUT del Coach están activas;
- intensidad del Coach es Equilibrado o Didáctico;
- existe al menos un LUT válido.

Se combinan:
- modo de escena seleccionado;
- luminancia promedio del preview;
- clipping de luces;
- clipping de sombras;
- perfil de todos los LUT disponibles.

Si hay un problema crítico de captura, el Coach puede no recomendar ningún LUT. Corregir exposición sigue teniendo prioridad sobre elegir un look.

### Tendencias por escena

| Escena | Tendencia buscada |
| --- | --- |
| Retrato | calidez moderada, contraste/saturación contenidos |
| Arquitectura | contraste con color relativamente neutro |
| Automotriz | contraste + saturación |
| Macro | saturación + separación tonal |
| Calle | contraste, saturación contenida |
| Paisaje | saturación + contraste + compresión de luces |
| Noche | levantar sombras + comprimir luces |
| General | transformación conservadora cercana a neutro |

Las condiciones de exposición pueden cambiar esa prioridad.

### Control del usuario

CapturePilot **nunca aplica automáticamente** una recomendación.

El Coach muestra:
- **LUT recomendado**;
- nombre;
- motivo;
- botón explícito para aplicarlo.

Al aceptar, el LUT se valida de nuevo y se copia al cache activo local. El RAW continúa intacto; el look sólo afecta el JPEG para compartir.

### Privacidad

Escaneo, parseo, perfilado, recomendación y aplicación son completamente locales.

No se suben LUTs, perfiles, frames ni recomendaciones.

### Validación pendiente

Falta aceptar físicamente:
- carpeta local de Archivos;
- iCloud Drive;
- File Providers de terceros disponibles;
- altas/bajas/renombres mientras la app está abierta;
- cambios hechos en background;
- persistencia tras relanzar/reiniciar;
- carpeta movida/bookmark stale;
- subcarpetas;
- bibliotecas grandes;
- LUT 17³/33³/65³;
- archivos inválidos;
- estabilidad de recomendaciones;
- perfiles conocidos contra referencias.
