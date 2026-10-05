# TestFlight Release Readiness / Preparación para TestFlight

**Candidate:** CapturePilot 0.9.3 (Build 12)

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
- Version/build fixed to 0.9.3 (12).
- Bundle ID `com.tiburonns.CapturePilot`.
- iPhone-only target.
- iOS 17 minimum deployment target.
- Full-screen camera contract.
- Four declared interface orientations.
- 1024 App Store icon source.
- Camera and Photo Library add-only permission descriptions.
- Personal-Team-safe startup without iCloud/CloudKit entitlements.
- Default Privacy Manifest declares no collected data because Friends/CloudKit is not compiled in.
- CloudKit privacy-disclosure template remains documented separately.
- UserDefaults required-reason API declaration CA92.1.
- Deterministic LUT recommendation tests.
- Release documentation for Rankings, Friends/CloudKit, and Creative Spark.

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

### Apple Developer / signing gates

For the **default non-CloudKit build**, core device testing can use a Personal Team. CloudKit/Friends is not part of that build.

**TestFlight distribution itself requires an active Apple Developer Program membership and App Store Connect access.** A free/Personal Team can validate the app on the developer's own devices, but cannot complete the TestFlight distribution steps.

For a future Friends-enabled distribution build:

- a compatible Apple Developer Team is required;
- App ID exists for `com.tiburonns.CapturePilot`;
- iCloud + CloudKit are enabled;
- container `iCloud.com.tiburonns.CapturePilot` exists and is assigned;
- `CapturePilot.entitlements` is attached to the target;
- `CAPTUREPILOT_CLOUDKIT` is added to Swift Active Compilation Conditions;
- provisioning contains the expected CloudKit entitlements;
- Product > Archive succeeds with signing enabled;
- Organizer > Validate App succeeds.

See `docs/CLOUDKIT_OPTIONAL.md`.

### CloudKit gates

Friends Rankings is optional for core photography but must be configured before claiming that feature works in TestFlight.

Development schema must contain and be exercised for:

**Private database**
- SocialIdentity

**Public database**
- CapturePilotProfile
- FriendRequest
- FriendAcceptance
- RankingScore

Verify QUERYABLE indexes used by the client:

- CapturePilotProfile.username
- FriendRequest.requesterID
- FriendRequest.addresseeID
- RankingScore.ownerID

Before distribution, deploy the tested development schema to the CloudKit production environment.

Then validate the social feature with two real iCloud accounts/devices.

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

For the default 0.9.3 candidate, App Privacy should reflect the non-CloudKit binary. If the optional Friends build is submitted later, update the bundled privacy manifest and App Privacy answers to disclose pseudonymous User ID and synchronized score/user-content metadata for app functionality, with no tracking.

### Go / no-go definition

**Ready for Internal TestFlight** means:

1. `main` CI is green.
2. Physical critical-path camera test passes.
3. Signed Archive succeeds.
4. Validate App succeeds.
5. Build uploads and finishes App Store Connect processing.

**Ready for Friends/CloudKit TestFlight testing** additionally requires:

6. CloudKit production schema deployed.
7. Two-account social acceptance test passes.

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
- versión/build 0.9.3 (12).
- bundle ID `com.tiburonns.CapturePilot`.
- target sólo iPhone.
- mínimo iOS 17.
- contrato full-screen.
- cuatro orientaciones declaradas.
- icono App Store 1024.
- permisos de Cámara y guardar en Fotos.
- el target por defecto **no** adjunta entitlement iCloud/CloudKit.
- el Privacy Manifest por defecto no declara datos recopilados.
- la plantilla de privacidad social queda separada para la variante CloudKit.
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

### Apple Developer / firma

La build por defecto sin CloudKit puede probarse en dispositivo con Personal Team.

**Distribuir por TestFlight requiere una membresía activa de Apple Developer Program y acceso a App Store Connect.** Una cuenta gratuita/Personal Team sirve para validar la app en los dispositivos propios, pero no puede completar la distribución por TestFlight.

Para una futura build con Amigos:

- Team Apple Developer compatible;
- App ID `com.tiburonns.CapturePilot`;
- iCloud + CloudKit activados;
- contenedor `iCloud.com.tiburonns.CapturePilot`;
- `CapturePilot.entitlements` adjunto al target;
- `CAPTUREPILOT_CLOUDKIT` en Swift Active Compilation Conditions;
- provisioning con entitlements correctos;
- Archive firmado;
- Validate App sin errores.

Consulta `docs/CLOUDKIT_OPTIONAL.md`.

### CloudKit

Antes de probar Amigos en TestFlight:

**Privado**
- SocialIdentity

**Público**
- CapturePilotProfile
- FriendRequest
- FriendAcceptance
- RankingScore

Índices QUERYABLE:

- CapturePilotProfile.username
- FriendRequest.requesterID
- FriendRequest.addresseeID
- RankingScore.ownerID

Despliega el schema probado a producción y después prueba con dos cuentas/dispositivos iCloud.

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

**Listo para probar Amigos/CloudKit** además:

6. schema CloudKit en producción.
7. prueba con dos cuentas aprobada.

**Listo para External TestFlight** además:

8. información beta completa.
9. aprobación TestFlight App Review cuando Apple la solicite.
