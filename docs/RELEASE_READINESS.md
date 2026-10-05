# TestFlight Release Readiness / Preparación para TestFlight

**Candidate:** CapturePilot 0.10.0 (Build 13)

This document separates what the repository can prove automatically from what still requires a signed Apple distribution build, physical camera hardware, or App Store Connect configuration.

---

## English

### Repository / CI gates

The following are release gates and must be green before merging to `main`:

- Release build for iOS Simulator.
- Release build for iPhoneOS.
- Swift warnings treated as errors.
- Xcode 26 or later.
- iOS 26 SDK or later.
- Valid Info.plist.
- Valid PrivacyInfo.xcprivacy.
- Valid CapturePilot.entitlements template for the optional social build.
- Default target does **not** attach CloudKit entitlements.
- Default target does **not** define `CAPTUREPILOT_CLOUDKIT`.
- Version/build fixed to 0.10.0 (13).
- Bundle ID `com.tiburonns.CapturePilot`.
- iPhone-only target.
- iOS 17 minimum deployment target.
- Full-screen camera contract.
- Four declared interface orientations.
- 1024 App Store icon source.
- Camera and Photo Library add-only permission descriptions.
- Camera-first startup with no account requirement.
- Firebase is not configured until Account & Friends is opened.
- Missing Firebase configuration does not block local photography.
- Privacy Manifest discloses optional account/social data with no tracking.
- UserDefaults required-reason API declaration CA92.1.
- Deterministic LUT recommendation tests.
- Release documentation for Rankings, Account & Friends, and Creative Spark.

### Current CI result

The current `main` candidate has already passed:

- Release Simulator build.
- Release iPhoneOS build.
- release-contract validation.
- deterministic LUT recommendation tests.

This validates source/build integrity, **not physical camera behavior or App Store acceptance**.

### Physical-device gates

Before Archive, complete the relevant checklists in:

- `docs/TESTING.md`
- `docs/UI_LAYOUT.md`
- `docs/CREATIVE_SPARK.md`
- `docs/RANKINGS.md`
- `docs/RAW_SHARE_WORKFLOW.md`
- `docs/LUT_LIBRARY.md`

Minimum release-device coverage:

1. A recent Pro iPhone with RAW/ProRAW and high-resolution capture.
2. A second iPhone with different screen geometry when available.

Must verify on-device:

- edge-to-edge preview and safe-area HUD;
- portrait, landscape left/right and upside-down behavior;
- every physical lens exposed by the device;
- tap focus and AF/AE Lock;
- HEIF/JPEG/RAW/ProRAW output matches the selected label;
- actual output dimensions for every 12/24/48 MP option shown;
- RAW + Share JPEG produces the intended pair;
- LUT import/folder persistence and LUT output;
- Focus Peaking, Zebra, Histogram, False Color and scopes alignment;
- Creative Spark point alignment and false positives;
- Ranking persistence and post-shot analysis;
- thermal/memory behavior during repeated high-resolution capture/analysis.

### Account backend / signing gates

Core camera testing does not require an account or Firebase configuration.

For Account & Friends:

- create/register Firebase iOS app for `com.tiburonns.CapturePilot`;
- bundle a valid `GoogleService-Info.plist`;
- enable Google in Firebase Authentication;
- deploy `Firebase/firestore.rules`;
- set `GOOGLE_REVERSED_CLIENT_ID` to the Google reversed client ID;
- test Firestore rules with authenticated users.

For Apple provider support additionally:

- active Apple Developer Program membership;
- Sign in with Apple enabled on the App ID;
- Apple provider configured in Firebase;
- Sign in with Apple capability attached to the distribution build;
- provisioning includes `com.apple.developer.applesignin`.

Account & Friends must be tested with:
- Apple-only account;
- Google-only account;
- account with both providers linked;
- account deletion/revocation.

See `docs/ACCOUNTS_FIREBASE.md`.

### Backend security gates

Before broad external testing:

- Firestore rules deployed and verified;
- unauthenticated reads/writes rejected;
- users can write only their own profile;
- friendship documents limited to participants;
- scores writable only by owner;
- imported images cannot submit social scores;
- consider Firebase App Check before a large public rollout;
- consider server-side score verification before any prize/high-stakes competition.

### App Store Connect / TestFlight gates

Current Apple requirements relevant to this candidate:

- uploads must be built with Xcode 26 or later and the iOS 26 SDK or later;
- CapturePilot targets iOS 17, above Apple's current iOS 13 upload minimum;
- external TestFlight requires beta test information;
- the first external build may require TestFlight App Review;
- TestFlight builds expire after 90 days.

Before external testing, complete:

- Beta App Description;
- What to Test;
- Feedback Email;
- review contact information;
- export-compliance answers;
- current age-rating questionnaire;
- App Privacy answers consistent with `PrivacyInfo.xcprivacy`.

For 0.10, App Privacy must reflect the optional Apple/Google account flow: provider identity data handled by Firebase Authentication and pseudonymous friendship/score metadata stored for app functionality, with no tracking.

### Go / no-go definition

**Ready for Internal TestFlight** means:

1. `main` CI is green.
2. Physical critical-path camera test passes.
3. Signed Archive succeeds.
4. Validate App succeeds.
5. Build uploads and finishes App Store Connect processing.

**Ready for Account & Friends TestFlight testing** additionally requires:

6. Firebase providers + Firestore rules configured.
7. Apple/Google/provider-linking social acceptance tests pass.

**Ready for External TestFlight** additionally requires:

8. TestFlight beta information completed.
9. TestFlight App Review approval when Apple requires it.

---

## Español

### Gates de repositorio / CI

Antes de fusionar a `main` deben quedar verdes:

- Release Simulator.
- Release iPhoneOS.
- warnings Swift como errores.
- Xcode 26 o superior.
- SDK iOS 26 o superior.
- Info.plist válido.
- Privacy Manifest válido.
- entitlements válidos.
- versión/build 0.10.0 (13).
- bundle ID `com.tiburonns.CapturePilot`.
- target sólo iPhone.
- mínimo iOS 17.
- contrato full-screen.
- cuatro orientaciones declaradas.
- icono App Store 1024.
- permisos de Cámara y guardar en Fotos.
- la cuenta no se exige al inicio;
- Firebase sólo se inicializa al abrir Cuenta y amigos;
- el Privacy Manifest declara la recolección opcional de datos de cuenta/social sin tracking.
- UserDefaults CA92.1.
- tests deterministas LUT.
- documentación de Ranking, Amigos/CloudKit y Chispa creativa.

### Qué ya prueba CI

El candidato actual de `main` ya pasó:

- Release Simulator;
- Release iPhoneOS;
- contrato de release;
- tests LUT.

Esto prueba integridad de código/build, **no comportamiento físico ni aceptación de App Store**.

### Gates de dispositivo físico

Antes del Archive completa:

- `docs/TESTING.md`
- `docs/UI_LAYOUT.md`
- `docs/CREATIVE_SPARK.md`
- `docs/RANKINGS.md`
- `docs/RAW_SHARE_WORKFLOW.md`
- `docs/LUT_LIBRARY.md`

Cobertura mínima:

1. iPhone Pro reciente con RAW/ProRAW y alta resolución.
2. Segundo iPhone con geometría de pantalla distinta cuando esté disponible.

Validar:

- preview edge-to-edge y HUD seguro;
- vertical, ambos horizontales e invertido;
- lentes físicas;
- tap focus y AF/AE Lock;
- HEIF/JPEG/RAW/ProRAW reales;
- dimensiones reales de 12/24/48 MP;
- RAW + JPEG para compartir;
- LUT y persistencia de carpeta;
- Peaking/Cebras/Histograma/False Color/scopes;
- Chispa creativa;
- Ranking;
- memoria/temperatura.

### Backend de cuentas / firma

La cámara no requiere cuenta ni configuración Firebase.

Para Cuenta y amigos:

- registrar `com.tiburonns.CapturePilot` en Firebase;
- incluir `GoogleService-Info.plist`;
- activar Google Auth;
- desplegar `Firebase/firestore.rules`;
- configurar `GOOGLE_REVERSED_CLIENT_ID`.

Para Apple además:

- membresía Apple Developer activa;
- Sign in with Apple en el App ID;
- proveedor Apple configurado en Firebase;
- capability Sign in with Apple en la build firmada;
- provisioning correcto.

Probar cuenta Apple, Google, ambos proveedores vinculados y eliminación.

Consulta `docs/ACCOUNTS_FIREBASE.md`.

### Seguridad backend

Antes de external testing amplio:

- rules Firestore desplegadas;
- acceso sin auth rechazado;
- perfil sólo editable por su dueño;
- amistades limitadas a participantes;
- score sólo editable por dueño;
- importaciones excluidas de score social;
- considerar App Check;
- considerar validación server-side para competencias con premios.

### App Store Connect / TestFlight

Requisitos actuales relevantes:

- Xcode 26+;
- SDK iOS 26+;
- CapturePilot iOS 17 supera el mínimo actual de subida;
- external TestFlight necesita información beta;
- el primer build externo puede requerir TestFlight App Review;
- un build de TestFlight dura 90 días.

Antes de external testing completa:

- Beta App Description;
- What to Test;
- Feedback Email;
- contacto de review;
- export compliance;
- cuestionario actual de age rating;
- App Privacy consistente con el Privacy Manifest.

### Definición de listo

**Listo para Internal TestFlight**:

1. CI de `main` verde.
2. Prueba física crítica aprobada.
3. Archive firmado.
4. Validate App aprobado.
5. Build subido y procesado en App Store Connect.

**Listo para probar Cuenta y amigos** además:

6. Firebase providers + Firestore rules configurados.
7. pruebas Apple/Google/vinculación aprobadas.

**Listo para External TestFlight** además:

8. información beta completa.
9. aprobación TestFlight App Review cuando Apple la solicite.
