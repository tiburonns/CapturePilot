# Optional Accounts: Apple + Google / Cuentas opcionales: Apple + Google

CapturePilot 0.10 moves the optional Friends/score layer to a provider-neutral CapturePilot account.

**Core photography never requires an account.** The app still launches directly into the camera. Account setup is only entered from:

```text
Camera → Rankings → Account & Friends
```

Firebase is not configured at app launch. CapturePilot attempts to configure Firebase only when the Account & Friends screen is opened.

---

## English

### Account model

Firebase Authentication provides the canonical CapturePilot account ID (`uid`).

Supported providers:

- Sign in with Apple
- Google Sign-In

A single Firebase user can have both providers explicitly linked. Once linked, either provider can be used to access the same CapturePilot account.

CapturePilot does not automatically merge accounts by email. This is intentional because:
- Apple may provide a private relay address;
- different providers can expose different email addresses;
- silent merging risks combining the wrong users.

Provider linking must be initiated while already signed in to the account that should remain canonical.

### Automatic username

The public CapturePilot username is deterministic from the Firebase UID:

```text
PILOT-XXXXXXXXXXXX
```

CapturePilot stores only the minimal public profile required for discovery:
- automatic username;
- normalized username for exact lookup.

Email/name returned by Apple or Google remain authentication-provider data and are not copied into the public Firestore profile.

### No startup dependency

The camera and all local features remain available when:
- there is no Firebase project configured;
- the device is offline;
- the user never creates an account;
- authentication providers fail.

Local features include:
- camera;
- Coach;
- Creative Spark;
- LUT library;
- RAW + Share JPEG;
- private Rankings.

### Firebase project setup

1. Create/select a Firebase project.
2. Add the iOS app using bundle ID:
   `com.tiburonns.CapturePilot`
3. Download `GoogleService-Info.plist`.
4. Add it to the CapturePilot target in Xcode.
5. Enable **Authentication → Sign-in method → Google**.
6. Enable **Authentication → Sign-in method → Apple** when the Apple provider is being shipped.
7. Create a Firestore database.
8. Deploy `Firebase/firestore.rules`.

CapturePilot detects the bundled Firebase configuration only when Account & Friends opens.

### Google setup

Google Sign-In requires:
- `GoogleService-Info.plist`;
- the iOS OAuth client created/configured for `com.tiburonns.CapturePilot`;
- the reversed client ID registered as an iOS URL scheme.

The Xcode project exposes a build setting:

```text
GOOGLE_REVERSED_CLIENT_ID
```

Set it to the `REVERSED_CLIENT_ID` value from `GoogleService-Info.plist`.

The URL callback is handled by `CapturePilotAppDelegate`.

### Apple setup

Apple sign-in requires an active Apple Developer Program configuration.

For the App ID `com.tiburonns.CapturePilot`:
1. Enable **Sign in with Apple**.
2. Configure the Apple provider in Firebase according to Firebase's current Apple-auth instructions.
3. Attach the Sign in with Apple capability/entitlement to the distribution build.

`CapturePilot/CapturePilot.entitlements` is the source-controlled entitlement template.

It is **not forced onto the default target**, so a Personal Team/local build can still compile and run the camera without Apple sign-in.

At runtime, CapturePilot checks whether the signed binary actually contains the Sign in with Apple entitlement before enabling the Apple button.

### Account linking

When signed in:
- if Apple is not linked, the account screen offers Apple linking;
- if Google is not linked, the account screen offers Google linking.

Linking uses Firebase's provider-linking flow so the same Firebase UID remains the account identity.

If the provider credential is already owned by a different Firebase user, CapturePilot does not silently merge the two accounts.

### Account deletion

CapturePilot provides an in-app account deletion flow.

Deletion requires reauthentication through a provider already linked to the account.

For Apple-linked accounts, CapturePilot requests a new Apple authorization code, asks Firebase to revoke the Apple token, removes Firestore social data, and then deletes the Firebase user.

For Google-only accounts, CapturePilot reauthenticates with Google before deleting Firestore data and the Firebase user.

Local photos and the local Rankings database are not deleted by deleting the social account.

### Firestore model

#### `users/{uid}`

Minimal discoverable profile:
- `username`
- `usernameNormalized`
- `createdAt`
- `updatedAt`

#### `friendships/{relationshipID}`

One deterministic document per user pair:
- `requesterID`
- `requesterUsername`
- `addresseeID`
- `addresseeUsername`
- `status`: `pending` / `accepted`
- timestamps

#### `scores/{scoreID}`

Best opt-in score by account/category:
- `ownerID`
- `username`
- `category`
- `score`
- `scoreVersion`
- `capturedAt`

Only actual CapturePilot captures are eligible for social score sync. Imported photos remain local-only.

### Firestore security

Source-controlled rules are in:

`Firebase/firestore.rules`

The rules require Firebase Authentication.

Profiles can be read by authenticated users for exact username lookup. Users can only write their own profile.

Friendship documents can only be read/written by their two participants.

Scores are readable by authenticated users and writable/deletable only by their owner. The app itself restricts the displayed leaderboard to the current user and accepted friends.

For stronger abuse resistance before a large public release, add Firebase App Check and consider server-side score verification.

### Required physical/backend validation

Before declaring Accounts & Friends TestFlight-ready:

- Firebase config present in the signed build;
- Google sign-in on a real device;
- Apple sign-in on a real device;
- provider linking in both directions;
- provider-already-in-use error handling;
- sign out / restore session;
- exact username friend search;
- request / accept / remove friend;
- score opt-in / opt-out;
- delete account via Google;
- delete Apple-linked account including token revocation;
- two devices using the same linked account;
- one device without any account to confirm camera startup remains unchanged.

---

## Español

CapturePilot 0.10 migra Amigos/scores a una cuenta CapturePilot independiente del proveedor.

**La fotografía principal nunca requiere cuenta.** La app sigue abriendo directamente en la cámara. La cuenta sólo se encuentra en:

```text
Cámara → Ranking → Cuenta y amigos
```

Firebase no se configura al iniciar la app. CapturePilot intenta configurarlo únicamente cuando se abre Cuenta y amigos.

### Modelo de cuenta

Firebase Authentication proporciona el `uid` canónico.

Proveedores:
- Apple;
- Google.

Una misma cuenta puede vincular ambos proveedores explícitamente y posteriormente acceder con cualquiera.

No se fusionan cuentas automáticamente por correo. Apple puede usar relay privado y una fusión silenciosa podría unir identidades incorrectas.

### Username automático

```text
PILOT-XXXXXXXXXXXX
```

Se deriva del Firebase UID.

El perfil público de Firestore guarda sólo el username necesario para descubrimiento. Correo/nombre del proveedor no se copian al perfil público.

### Sin dependencia al inicio

Cámara, Coach, Chispa creativa, LUTs, RAW/JPEG y Ranking privado funcionan aunque:
- Firebase no esté configurado;
- no haya red;
- el usuario nunca inicie sesión.

### Configuración Firebase

1. Crear/seleccionar proyecto Firebase.
2. Registrar iOS con `com.tiburonns.CapturePilot`.
3. Descargar `GoogleService-Info.plist`.
4. Añadirlo al target.
5. Activar Google en Firebase Authentication.
6. Activar Apple cuando esa build incluya Apple.
7. Crear Firestore.
8. Desplegar `Firebase/firestore.rules`.

### Google

Configura el cliente iOS y asigna:

```text
GOOGLE_REVERSED_CLIENT_ID
```

al valor `REVERSED_CLIENT_ID` de `GoogleService-Info.plist`.

### Apple

En Apple Developer:
- habilita Sign in with Apple para `com.tiburonns.CapturePilot`;
- configura el proveedor Apple en Firebase;
- adjunta la capability a la build de distribución.

`CapturePilot.entitlements` contiene la plantilla, pero no se fuerza en el target por defecto.

### Vinculación

Dentro de una cuenta ya iniciada, el usuario puede vincular el proveedor faltante. Ambos métodos quedan asociados al mismo Firebase UID.

No se hace merge automático cuando el proveedor ya pertenece a otra cuenta.

### Eliminación

La app permite iniciar eliminación de cuenta.

Se exige reautenticación. Para Apple se obtiene un authorization code nuevo, se revoca el token mediante Firebase y después se elimina la cuenta.

Las fotos y Rankings locales permanecen en el dispositivo.

### Firestore

Colecciones:
- `users`
- `friendships`
- `scores`

Reglas:
`Firebase/firestore.rules`

Sólo las capturas reales de CapturePilot pueden aportar score social. Las importaciones continúan siendo privadas/locales.

### Pruebas pendientes

Antes de considerar lista la capa social:
- Google real;
- Apple real;
- vincular ambos;
- restaurar sesión;
- búsqueda por username;
- amistad;
- scores;
- eliminación de cuenta;
- dos dispositivos;
- y una prueba sin cuenta que confirme que CapturePilot sigue entrando directamente a cámara.
