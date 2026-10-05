# TestFlight Release Guide / Guía de publicación en TestFlight

## English

### Candidate

CapturePilot 0.10.0 build 13 compiles in Release for iOS Simulator and iPhoneOS in GitHub Actions.

The candidate includes capability-driven HEIF/RAW/ProRAW, maximum photo dimensions, RAW + Share JPEG, 12/24/48 MP share targets without upscaling, resolution selection, adaptive physical lens switching, manual controls, local geometric coaching, eight scene coach modes, professional monitoring/scopes, adaptive orientation, customizable HUD, and Focus Peaking.

The candidate also includes a persistent LUT library, private Top 5/10/25/50 Rankings with post-shot Coach review, and an optional Apple/Google account layer for Friends scores that does not upload photos.

For Creative Spark 0.9.1, specifically validate frame-within-frame false positives and lower-frame foreground alignment on real hardware.

Compilation does not prove physical camera behavior, external File Provider persistence, ranking quality, Firebase/provider configuration, or App Store acceptance.

### Current Apple upload requirements

As of October 2026:

- TestFlight/App Store Connect distribution requires Apple Developer Program membership; a Personal Team is only for direct development-device testing.

- App Store Connect uploads require Xcode 26 or later and the iOS 26 SDK or later.
- CapturePilot's CI currently uses Xcode 26.6 and the iOS 26.5 SDK, which satisfies that floor.
- Apple currently requires uploaded iOS apps to target iOS 13 or later; CapturePilot targets iOS 17.
- Starting April 2027 Apple has announced an iOS 27 SDK requirement, so recheck this gate before future releases.

See [RELEASE_READINESS.md](RELEASE_READINESS.md) for the complete go/no-go matrix.

### Before Archive

Complete the physical checklists in:

- `docs/TESTING.md`
- `docs/UI_LAYOUT.md`

At minimum use:

- one recent Pro iPhone capable of ProRAW/high-resolution capture;
- one smaller/notched or otherwise different-layout iPhone when available.

Record actual dimensions for every resolution shown.

### LUT library acceptance

Before Archive, test at least:

- select a LUT folder under On My iPhone;
- select a LUT folder under iCloud Drive;
- relaunch CapturePilot and verify the folder can be reopened;
- add/remove/rename a .cube and verify refresh;
- verify nested folders;
- verify invalid LUTs are not offered;
- apply a LUT recommended by the Coach;
- confirm the RAW remains unaffected and the Share JPEG uses the selected LUT;
- confirm the recommendation is never applied automatically.

If a third-party File Provider is available, test it separately and record provider/app version.

### Creative Spark acceptance

Before Archive:
- verify ✦ is optional/hideable;
- scan in every supported orientation;
- verify markers against faces, salient objects, lines and vanishing geometry;
- verify aspect-fill alignment on at least two different screen geometries;
- verify changing lens/scene clears stale results;
- verify a low-signal scene does not invent numbered interest points;
- verify no camera parameter changes after a Creative Spark scan;
- repeat scans while monitoring preview responsiveness.

### No-account startup smoke test

Validate the app with no Firebase configuration and no signed-in account:

- [ ] App launches directly into the camera.
- [ ] No account/login sheet appears automatically.
- [ ] Camera permission flow works.
- [ ] Live Coach works.
- [ ] Creative Spark works.
- [ ] LUT library works.
- [ ] RAW/JPEG workflow remains available when hardware supports it.
- [ ] Private Rankings opens and imports/analyzes photos.
- [ ] Account & Friends can be opened manually and explains that accounts are not configured.
- [ ] No Firebase/Auth error prevents local use.

This is the required fallback behavior for every CapturePilot build.

### Rankings acceptance

Before Archive, verify on a physical iPhone:

- automatic ranking after a CapturePilot HEIF/JPEG capture;
- RAW/ProRAW ranking without crash;
- RAW+JPG creates one ranking entry from the processed share JPEG;
- Top 5/10/25/50;
- every category filter;
- imported photos remain local;
- iOS 18+ shows Vision aesthetics as supplemental information without changing the cross-version Coach Score formula;
- recommendations are sensible on a varied real photo set.

### Accounts / Friends acceptance

Before considering the optional account layer TestFlight-ready:

- add a valid `GoogleService-Info.plist` to the target;
- enable Firebase Authentication for Google;
- enable Firebase Authentication for Apple when shipping Apple sign-in;
- deploy `Firebase/firestore.rules`;
- set `GOOGLE_REVERSED_CLIENT_ID` from `GoogleService-Info.plist`;
- add Sign in with Apple capability to the signed distribution build;
- verify app launch still goes directly to the camera;
- test Google sign-in on a real device;
- test Apple sign-in on a real device;
- link Apple → existing Google account;
- link Google → existing Apple account;
- test provider-already-in-use handling;
- sign out and restore a session;
- test friend request/accept/remove;
- test score opt-in/opt-out;
- confirm imported photos never affect shared scores;
- confirm photos/thumbnails never appear in Firestore;
- delete a Google account in-app;
- delete an Apple-linked account including Apple token revocation.

See [ACCOUNTS_FIREBASE.md](ACCOUNTS_FIREBASE.md) and [SOCIAL_COMPETITION.md](SOCIAL_COMPETITION.md).

### Archive

1. Pull latest `main`.
2. Open `CapturePilot.xcodeproj`.
3. Select the paid Apple Developer Team.
4. Confirm Bundle Identifier.
5. Select Generic iOS Device / eligible device.
6. Product > Archive.
7. Organizer > Validate App.
8. Resolve errors and understood warnings.
9. Distribute App > App Store Connect > Upload.

### TestFlight

- Confirm **0.10.0 (13)**.
- Complete export compliance as requested.
- Fill beta description, What to Test, feedback email, and review contact.
- Complete the current age-rating questionnaire.
- Complete App Privacy answers so they match the Privacy Manifest and optional Friends data flow.
- Start with Internal Testing.
- Verify HEIF/JPEG/RAW/ProRAW labels match actual output on the test hardware.
- Verify RAW+JPG output dimensions, LUT-library persistence, and Coach LUT recommendation/apply behavior.
- Do not advertise 24/48 MP, ProRAW, telephoto, or manual modes on devices where CapturePilot does not expose those capabilities.

---

## Español

### Candidato

CapturePilot 0.10.0 build 13 compila en Release para Simulator e iPhoneOS mediante GitHub Actions.

Incluye HEIF/RAW/ProRAW condicionados por capability, dimensiones máximas, RAW + JPEG para compartir, objetivos 12/24/48 MP sin upscale, selector de resolución, lentes físicas, controles manuales, análisis geométrico local, ocho coaches de escena, monitoreo profesional/scopes, orientación adaptativa, HUD y Focus Peaking.

El candidato también incluye biblioteca LUT persistente desde una carpeta de Archivos y recomendaciones LUT explicables del Coach.

Compilar no demuestra comportamiento físico, persistencia de File Providers externos, calidad de recomendaciones ni aceptación de App Store.

### Requisitos actuales de subida

A septiembre de 2026:

- App Store Connect requiere Xcode 26 o superior y SDK iOS 26 o superior.
- CI usa actualmente Xcode 26.6 y SDK iOS 26.5, por encima de ese mínimo.
- Apple exige actualmente target iOS 13 o superior; CapturePilot usa iOS 17.
- Apple anunció SDK iOS 27 para abril de 2027; hay que volver a comprobar este gate en futuras versiones.

Consulta [RELEASE_READINESS.md](RELEASE_READINESS.md) para la matriz completa.

### Antes del Archive

Completa:

- `docs/TESTING.md`
- `docs/UI_LAYOUT.md`

Usa al menos un iPhone Pro reciente capaz de ProRAW/alta resolución y, cuando sea posible, otro modelo con geometría de pantalla distinta.

Registra las dimensiones reales de cada resolución mostrada.

### Aceptación de biblioteca LUT

Antes del Archive prueba al menos:

- seleccionar carpeta LUT en En mi iPhone;
- seleccionar carpeta LUT en iCloud Drive;
- relanzar CapturePilot y comprobar que puede reabrirla;
- agregar/eliminar/renombrar un .cube y comprobar refresh;
- verificar subcarpetas;
- comprobar que LUT inválidos no se ofrecen;
- aplicar un LUT recomendado por el Coach;
- confirmar que RAW no cambia y el JPEG para compartir usa el LUT activo;
- confirmar que la recomendación nunca se aplica automáticamente.

Si existe un File Provider de terceros, pruébalo por separado y registra proveedor/versión.

### Aceptación de Chispa creativa

Antes del Archive:
- comprobar que ✦ es opcional/ocultable;
- escanear en todas las orientaciones;
- verificar puntos contra rostros, saliencia, líneas y punto de fuga;
- verificar aspect-fill en al menos dos geometrías de pantalla;
- comprobar limpieza al cambiar lente/escena;
- comprobar que una escena sin señal fiable no genera puntos inventados;
- confirmar que no cambia parámetros de cámara;
- repetir scans y observar fluidez del preview.

### Smoke test sin cuenta

Valida la app sin Firebase configurado y sin sesión:

- [ ] Entra directamente a la cámara.
- [ ] No aparece login automáticamente.
- [ ] Permiso de cámara correcto.
- [ ] Coach funciona.
- [ ] Chispa creativa funciona.
- [ ] Biblioteca LUT funciona.
- [ ] RAW/JPEG sigue disponible cuando el hardware lo soporta.
- [ ] Ranking privado abre/importa/analiza.
- [ ] Cuenta y amigos puede abrirse manualmente y explica que no está configurado.
- [ ] Ningún error de Firebase/Auth bloquea el uso local.

Este fallback es obligatorio en todas las builds.

### Aceptación del Ranking

Antes del Archive verifica en iPhone real:

- ranking automático tras captura HEIF/JPEG;
- RAW/ProRAW sin crash;
- RAW+JPG crea una sola entrada desde el JPEG procesado;
- Top 5/10/25/50;
- filtros por categoría;
- importaciones permanecen locales;
- iOS 18+ muestra estética Vision como información suplementaria sin cambiar la fórmula comparable del Coach Score;
- recomendaciones razonables con fotos reales diversas.

### Aceptación de cuentas / Amigos

Antes de considerarla lista para TestFlight:

- añadir `GoogleService-Info.plist` válido;
- activar Google en Firebase Authentication;
- activar Apple cuando esa build lo incluya;
- desplegar `Firebase/firestore.rules`;
- configurar `GOOGLE_REVERSED_CLIENT_ID`;
- añadir Sign in with Apple a la build firmada;
- confirmar que el inicio sigue entrando directamente a cámara;
- probar Google real;
- probar Apple real;
- vincular ambos proveedores a la misma cuenta;
- probar credencial ya usada por otra cuenta;
- cerrar/restaurar sesión;
- solicitud/aceptación/eliminación de amistad;
- opt-in/opt-out de scores;
- confirmar que importaciones no suben score;
- confirmar que fotos/miniaturas no suben a Firestore;
- eliminar cuenta Google;
- eliminar cuenta con Apple incluyendo revocación.

Consulta [ACCOUNTS_FIREBASE.md](ACCOUNTS_FIREBASE.md) y [SOCIAL_COMPETITION.md](SOCIAL_COMPETITION.md).

### Archive

1. Actualiza `main`.
2. Abre `CapturePilot.xcodeproj`.
3. Selecciona tu Team de pago.
4. Confirma Bundle Identifier.
5. Selecciona Generic iOS Device/dispositivo válido.
6. Product > Archive.
7. Organizer > Validate App.
8. Corrige errores y revisa warnings.
9. Distribute App > App Store Connect > Upload.

### TestFlight

- Confirma **0.10.0 (13)**.
- Completa export compliance.
- Completa descripción beta, Qué probar, email de feedback y contacto de review.
- Completa el cuestionario vigente de age rating.
- Completa App Privacy de forma consistente con el Privacy Manifest y Amigos opcional.
- Empieza con Internal Testing.
- Comprueba que HEIF/JPEG/RAW/ProRAW coincidan con el archivo real.
- Verifica dimensiones RAW+JPG, persistencia de biblioteca LUT y comportamiento de recomendación/aplicación del Coach.
- No anuncies 24/48 MP, ProRAW, telefoto o controles manuales en hardware donde CapturePilot no los exponga.
