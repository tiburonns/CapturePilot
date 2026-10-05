# Friends Rankings / Ranking con amigos

CapturePilot Friends is an **optional account feature** inside the Rankings section.

It is not part of camera startup and it is not required for any local photography workflow.

See [Optional Accounts: Apple + Google](ACCOUNTS_FIREBASE.md) for provider/backend setup.

---

## English

### Identity

The canonical social identity is a Firebase Authentication UID.

A photographer can create/access the account with:
- Apple;
- Google.

The second provider can be explicitly linked to the same account.

CapturePilot publishes an automatic pseudonymous username derived from the UID:

`PILOT-XXXXXXXXXXXX`

### Social scope

Friends can compare:
- Overall best Coach Score;
- General;
- Portrait;
- Architecture;
- Automotive;
- Macro;
- Street;
- Landscape;
- Night.

Score sharing is opt-in.

Only scores from photos captured inside CapturePilot are eligible. Imported images participate in the private ranking but are never submitted to Friends Rankings.

### What is synchronized

When enabled:
- automatic CapturePilot username;
- account UID needed by the relationship/security model;
- category;
- Coach Score;
- score version;
- capture date;
- friendship state.

### What is not synchronized

CapturePilot does not upload to Friends Rankings:
- RAW;
- JPEG;
- ranking thumbnails;
- LUT files;
- complete photo tags;
- recommendation text.

Photos remain local in this version.

### Account data vs public profile

Apple/Google authentication can provide account information such as email and display name to Firebase Authentication.

CapturePilot does **not** copy that provider email/name into its public Firestore profile.

The public profile contains only the automatic CapturePilot username required for discovery.

### Friendly competition

Scores are calculated on-device.

Restricting submissions to CapturePilot captures reduces obvious abuse, but a modified client could still falsify a score.

Do not present Friends Rankings as anti-cheat or suitable for prizes without trusted server-side validation.

### Future photo sharing

Showing friends' actual photographs would add user-generated-content obligations.

Before enabling that, CapturePilot should have:
- reporting;
- blocking;
- moderation;
- objectionable-content handling;
- support/contact process.

0.10 keeps the social layer score-only.

---

## Español

Amigos es una función de cuenta **opcional** dentro de Ranking.

No participa en el inicio de la cámara y no es requisito para las funciones locales.

Consulta [Cuentas opcionales: Apple + Google](ACCOUNTS_FIREBASE.md).

### Identidad

La identidad canónica es el Firebase UID.

Se puede acceder con:
- Apple;
- Google.

El segundo proveedor puede vincularse explícitamente a la misma cuenta.

Username automático:
`PILOT-XXXXXXXXXXXX`

### Ranking social

Se compara:
- Overall;
- General;
- Retrato;
- Arquitectura;
- Automotriz;
- Macro;
- Calle;
- Paisaje;
- Noche.

Compartir scores es opt-in.

Sólo capturas hechas dentro de CapturePilot pueden aportar score. Las fotos importadas permanecen en ranking privado.

### Se sincroniza

- username automático;
- UID necesario para seguridad/amistad;
- categoría;
- Coach Score;
- versión del score;
- fecha;
- estado de amistad.

### No se sincroniza

- RAW;
- JPEG;
- miniaturas;
- LUT;
- tags completos;
- texto de recomendaciones.

### Datos del proveedor

Firebase Authentication puede recibir correo/nombre del proveedor Apple/Google. CapturePilot no copia esos datos al perfil público de Firestore.

### Competencia amistosa

El score se calcula en cliente. No es anti-cheat certificado.

### Compartir fotos después

Antes de mostrar fotos de otros usuarios deben existir reportes, bloqueo, moderación y manejo de contenido. 0.10 continúa siendo social por scores, no por fotografías.
