# Privacy / Privacidad

## English

CapturePilot does not create an account, serve ads, include third-party analytics, or upload camera frames to a CapturePilot server.

### Protected resources

- Camera: live viewfinder, local coach/geometric analysis, Focus Peaking, professional monitoring, and photo capture.
- Photo Library add-only: save photos explicitly captured by the user.
- Files folder selected by the user: optional LUT-library access. CapturePilot cannot scan arbitrary Files locations; the photographer explicitly chooses a directory with the system picker.

### Local processing

The following run on-device:

- Vision face/person/saliency/horizon requests;
- luminance and clipping sampling;
- leading-line / symmetry / vanishing-point / negative-space heuristics;
- Focus Peaking edge analysis;
- Zebra/Histogram/False Color/Waveform/RGB Parade/Vectorscope preview analysis;
- .cube parsing and LUT transform profiling;
- scene/exposure-aware LUT recommendation;
- Core Image LUT application to the Share JPEG.

No networking dependency is required for these features.

### LUT folder access

When the photographer chooses an external LUT directory, CapturePilot stores bookmark data in UserDefaults so the app can attempt to reopen that same authorized directory on later launches.

When access is available, CapturePilot uses security-scoped file access and coordinates reads through Foundation file-coordination APIs. The external LUT itself is not uploaded. A LUT selected for capture is validated and copied into app-local storage before the shutter workflow uses it.

Removing the external LUT folder from CapturePilot clears the stored directory bookmark. If an active LUT came from that external folder, its active selection/cache is also cleared.

### Rankings data

Private photo ranking runs on-device.

CapturePilot may locally store:
- reduced JPEG thumbnails;
- Coach Score breakdowns;
- categories/tags;
- recommendation identifiers;
- capture/import source;
- timestamps;
- SHA-256 duplicate fingerprints.

Imported full-resolution originals are not copied into the ranking store.

### Optional social identity and scores

Core photography and private Rankings do not require an account.

If the photographer opts into Friends, CapturePilot requires an available iCloud account and creates a random CapturePilot social identity in that account's private CloudKit database. CapturePilot does not receive the person's Apple Account email or password.

A minimal discoverable profile plus friend/score records use the public CloudKit database. Because that database is public, synchronized social metadata must not be treated as secret.

0.8 uploads **no photo pixels or thumbnails** to the social database.

Optional shared fields are:
- automatic Pilot-* username;
- category;
- Coach Score;
- capture date;
- pseudonymous identifiers needed for friendship records.

Imported-image scores are not eligible for social upload.

See [SOCIAL_COMPETITION.md](SOCIAL_COMPETITION.md).

### Privacy Manifest in 0.8

CapturePilot still declares **no tracking**.

Because the optional Friends feature writes pseudonymous identity/score metadata to CloudKit, the manifest declares:

- User ID — linked, not used for tracking, app functionality;
- Other User Content — linked, not used for tracking, app functionality.

This declaration applies to the optional social layer; it does not mean camera frames or ranking thumbnails are uploaded.

### Local preferences

UserDefaults stores app-local settings such as language, guide, coach intensity/scene, orientation policy, HUD layout, LUT recommendation preference, external-folder bookmark data, and active LUT identifiers/names.

`PrivacyInfo.xcprivacy` declares:

- Tracking: false.
- Tracking domains: none.
- Collected data types: none.
- Required Reason API: UserDefaults / CA92.1.

If networking, accounts, analytics, crash SDKs, cloud AI, or additional Required Reason APIs are added later, this document and the manifest must be reviewed before release.

---

## Español

CapturePilot no crea cuenta, no sirve publicidad, no incluye analítica de terceros y no sube frames de cámara a un servidor de CapturePilot.

### Recursos protegidos

- Cámara: visor, Coach/análisis geométrico local, Focus Peaking, monitoreo profesional y captura.
- Fototeca add-only: guardar fotos tomadas explícitamente por la persona.
- Carpeta de Archivos seleccionada por el usuario: acceso opcional a biblioteca LUT. CapturePilot no escanea ubicaciones arbitrarias; la persona elige explícitamente una carpeta mediante el selector del sistema.

### Procesamiento local

Se ejecutan localmente:

- Vision para rostro/persona/saliencia/horizonte;
- luminancia y clipping;
- líneas/simetría/punto de fuga/espacio negativo;
- Focus Peaking;
- Zebra/Histograma/False Color/Waveform/RGB Parade/Vectorscope;
- parseo .cube y perfilado del transform LUT;
- recomendación LUT según escena/exposición;
- aplicación Core Image del LUT al JPEG para compartir.

No requieren una dependencia de red.

### Acceso a carpeta LUT

Cuando la persona selecciona una carpeta LUT externa, CapturePilot guarda bookmark data en UserDefaults para intentar reabrir esa misma carpeta autorizada en lanzamientos posteriores.

Cuando hay acceso, CapturePilot usa security-scoped access y coordinación de archivos de Foundation. Los LUT externos no se suben. El LUT elegido para captura se valida y se copia al almacenamiento local de la app antes de usarlo en el disparo.

Eliminar la carpeta externa desde CapturePilot borra el bookmark guardado. Si el LUT activo provenía de esa carpeta, también se limpia su selección/cache activo.

### Datos del Ranking

El ranking privado se analiza localmente.

CapturePilot puede guardar localmente:
- miniaturas JPEG reducidas;
- desglose Coach Score;
- categorías/tags;
- recomendaciones;
- origen captura/importación;
- fechas;
- fingerprints SHA-256 para duplicados.

El original full-resolution importado no se copia al almacén del ranking.

### Identidad y scores sociales opcionales

La cámara y el ranking privado no requieren cuenta.

Si el fotógrafo activa Amigos, CapturePilot requiere una cuenta iCloud disponible y crea una identidad social aleatoria en la base privada de CloudKit de esa cuenta. CapturePilot no recibe correo ni contraseña visibles de la cuenta Apple.

Un perfil mínimo descubrible y los registros de amistad/score usan la base pública de CloudKit. Esa metadata debe tratarse como social/pública dentro del servicio, no como información secreta.

0.8 **no sube píxeles ni miniaturas**.

Campos opcionales compartidos:
- username Pilot-*;
- categoría;
- Coach Score;
- fecha;
- identificadores pseudónimos necesarios para amistad.

Los scores de imágenes importadas no son elegibles para subida social.

Consulta [SOCIAL_COMPETITION.md](SOCIAL_COMPETITION.md).

### Privacy Manifest en 0.8

CapturePilot sigue declarando **sin tracking**.

Como Amigos opcional sincroniza identidad pseudónima y metadata de score en CloudKit, el manifest declara:

- User ID — vinculado, sin tracking, funcionalidad;
- Other User Content — vinculado, sin tracking, funcionalidad.

Esto corresponde a la capa social opcional; no significa que se suban frames de cámara ni miniaturas del Ranking.

### Preferencias

UserDefaults conserva idioma, guía, intensidad/escena del Coach, orientación, HUD, preferencia de recomendaciones LUT, bookmark de carpeta externa e identificadores/nombres del LUT activo.

`PrivacyInfo.xcprivacy` declara:

- Tracking: falso.
- Dominios: ninguno.
- User ID — vinculado, sin tracking, funcionalidad.
- Other User Content — vinculado, sin tracking, funcionalidad.
- Required Reason API: UserDefaults / CA92.1.

Si en el futuro se agregan red, cuentas, analytics, SDK de crashes, IA cloud u otras Required Reason APIs, se debe revisar este documento y el manifest.
