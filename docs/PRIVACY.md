# Privacy / Privacidad

## English

CapturePilot does not require an account for photography, serves no ads, includes no third-party analytics, and does not upload camera frames to the account backend. An optional Apple/Google account is available only inside Rankings → Account & Friends.

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

### Optional account and Friends scores

Core photography and private Rankings do not require an account.

If the photographer opens Account & Friends and signs in, Firebase Authentication provides a provider-neutral CapturePilot UID. Apple and Google can be linked explicitly to the same account.

Firebase Authentication can receive provider identity data such as user ID, email, and display name. CapturePilot does not copy provider email/name into its discoverable Firestore profile.

Firestore stores only the social data needed for the feature:
- automatic PILOT-* username;
- Firebase UID used by security/relationship records;
- friendship state;
- category;
- Coach Score and score version;
- capture date.

No RAW, JPEG, ranking thumbnail, or camera frame is uploaded by Friends Rankings.

Imported-image scores are not eligible for social upload.

Firebase is configured only when Account & Friends is opened and a valid bundled Firebase configuration exists. Missing account configuration never blocks camera startup or local Rankings.

See [ACCOUNTS_FIREBASE.md](ACCOUNTS_FIREBASE.md) and [SOCIAL_COMPETITION.md](SOCIAL_COMPETITION.md).

### Privacy Manifest in 0.10

CapturePilot declares **no tracking**.

Because the optional account feature is present in the binary, the app-level manifest declares data that can be collected when the user explicitly signs in:
- User ID;
- Email Address;
- Name;
- Other User Content (social score metadata).

All are declared as linked to the user, used for app functionality, and not used for tracking.

UserDefaults remains declared under Required Reason API CA92.1.

Firebase/Google SDKs also ship their own privacy manifests; App Store Connect privacy answers must describe the complete behavior of the signed binary.

### Local preferences

UserDefaults stores app-local settings such as language, guide, coach intensity/scene, orientation policy, HUD layout, LUT recommendation preference, external-folder bookmark data, and active LUT identifiers/names.

`PrivacyInfo.xcprivacy` declares:

- Tracking: false.
- Tracking domains: none.
- Datos opcionales de cuenta/social declarados cuando corresponden al binario 0.10.
- Required Reason API: UserDefaults / CA92.1.

If networking, accounts, analytics, crash SDKs, cloud AI, or additional Required Reason APIs are added later, this document and the manifest must be reviewed before release.

---

## Español

CapturePilot no exige cuenta para fotografía, no sirve publicidad, no incluye analítica de terceros y no sube frames de cámara al backend de cuentas. Apple/Google es opcional y sólo aparece dentro de Ranking → Cuenta y amigos.

### Recursos protegidos

- Cámara: visor, Coach/análisis geométrico local, Focus Peaking, monitoreo profesional y captura.
- Fototeca add-only: guardar fotos tomadas explícitamente por la persona.
- Carpeta de Archivos seleccionada por el usuario: acceso opcional a biblioteca LUT. CapturePilot no escanea ubicaciones arbitrarias; la persona elige explícitamente una carpeta mediante el selector del sistema.

### Procesamiento local

Se ejecutan localmente:

- Vision para rostro/persona/saliencia/horizonte;
- scan bajo demanda de Chispa creativa con saliencia/rostro/persona;
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

### Cuenta opcional y scores con amigos

La cámara y el Ranking privado no requieren cuenta.

Al entrar a Cuenta y amigos, Firebase Authentication puede crear una identidad CapturePilot independiente del proveedor. Apple y Google pueden vincularse explícitamente a la misma cuenta.

Firebase Authentication puede recibir identificador, correo y nombre que entregue el proveedor. CapturePilot no copia correo/nombre al perfil público de Firestore.

Firestore guarda únicamente:
- username PILOT-*;
- Firebase UID necesario para seguridad/amistad;
- relaciones de amistad;
- categoría;
- Coach Score y versión;
- fecha.

Amigos no sube RAW, JPEG, miniaturas ni frames.

Las importaciones no son elegibles para score social.

Firebase sólo se configura al abrir Cuenta y amigos y cuando existe configuración válida. Una configuración ausente nunca bloquea la cámara ni el Ranking local.

Consulta [ACCOUNTS_FIREBASE.md](ACCOUNTS_FIREBASE.md) y [SOCIAL_COMPETITION.md](SOCIAL_COMPETITION.md).

### Privacy Manifest en 0.10

CapturePilot declara **sin tracking**.

Como la función opcional de cuenta está presente en el binario, el manifest declara datos que pueden recopilarse cuando el usuario inicia sesión:
- User ID;
- Email Address;
- Name;
- Other User Content (metadata social de scores).

Se declaran vinculados al usuario, para funcionalidad y sin tracking.

UserDefaults continúa con Required Reason API CA92.1.

Los SDK de Firebase/Google también incluyen sus propios manifests; App Store Connect debe reflejar el comportamiento completo del binario firmado.

### Preferencias

UserDefaults conserva idioma, guía, intensidad/escena del Coach, orientación, HUD, preferencia de recomendaciones LUT, bookmark de carpeta externa e identificadores/nombres del LUT activo.

`PrivacyInfo.xcprivacy` declara:

- Tracking: falso.
- Dominios: ninguno.
- Datos opcionales de cuenta/social: User ID, Email Address, Name y Other User Content para funcionalidad, sin tracking.
- Required Reason API: UserDefaults / CA92.1.

Si en el futuro se agregan red, cuentas, analytics, SDK de crashes, IA cloud u otras Required Reason APIs, se debe revisar este documento y el manifest.
