# Friends + Social Scores / Amigos + scores sociales

CapturePilot 0.8 introduces an opt-in social score layer for friendly comparison without uploading friend photos.

---

## English

### Identity: Sign in with Apple

CapturePilot does **not** read a person's Apple ID email, password, or account name.

The social flow uses **Sign in with Apple**. After successful authentication, Apple provides an `ASAuthorizationAppleIDCredential.user` identifier.

CapturePilot hashes that opaque identifier locally and derives an automatic public CapturePilot username such as:

```text
Pilot-A1B2C3D4E5
```

The username is therefore tied to the stable Sign in with Apple identity available to the developer, not to the person's visible Apple ID address.

### Local identity state

The current implementation stores the returned Apple user identifier locally so CapturePilot can ask Apple for credential state on later launches.

If Apple reports that the authorization is no longer valid, CapturePilot clears the local social session.

### CloudKit

Social metadata uses:

```text
iCloud.com.tiburonns.CapturePilot
```

and the container's **public CloudKit database**.

Current record types:

#### CapturePilotProfile

| Field | Type | Purpose |
| --- | --- | --- |
| userHash | String | Pseudonymous public identity key |
| username | String | Automatic Pilot-* username |
| createdAt | Date | Profile creation |

#### FriendConnection

| Field | Type |
| --- | --- |
| requesterHash | String |
| requesterUsername | String |
| addresseeHash | String |
| addresseeUsername | String |
| status | String: pending/accepted |
| createdAt | Date |

The deterministic record ID is based on the sorted pair of user hashes, preventing multiple parallel accepted connections for the same pair.

#### RankingScore

| Field | Type |
| --- | --- |
| ownerHash | String |
| username | String |
| category | String |
| score | Double |
| capturedAt | Date |

CapturePilot stores at most one current best-score record per user/category record ID.

### Friend flow

1. Sign in with Apple.
2. CapturePilot creates/restores the pseudonymous profile.
3. Search/add by exact CapturePilot username.
4. The other user sees an incoming request.
5. Accept.
6. Accepted users appear in the friends list.
7. The leaderboard contains the current user's and accepted friends' shared best scores.

### Leaderboard filters

Friends leaderboard supports:

- Overall;
- General;
- Portrait;
- Architecture;
- Automotive;
- Macro;
- Street;
- Landscape;
- Night.

Only scores from **CapturePilot-captured photos** are eligible for upload.

### Opt-in score sharing

Score sharing is off until the photographer enables it.

When enabled, CapturePilot can sync:

- automatic username;
- category;
- Coach Score;
- capture date.

CapturePilot 0.8 does **not** upload:

- the photo;
- ranking thumbnail;
- RAW;
- JPEG;
- LUT;
- photo tags;
- recommendation text;
- Apple ID email/password/name.

### Public CloudKit privacy boundary

CapturePilot currently uses the **public** CloudKit database so profiles can be discovered by username and friends can compare scores.

Apple documents that public-database contents are readable by users of the app according to the CloudKit security model.

Therefore, the synchronized fields above must be treated as **public/pseudonymous social metadata**, not secret data.

Photos remain local.

### Friendly competition, not anti-cheat

The app limits synced scores to photos captured by CapturePilot, but 0.8 still performs scoring on the client.

A modified client could potentially falsify a score before CloudKit submission.

For a high-stakes or prize competition, CapturePilot would need a trusted validation service that verifies identity tokens and score submissions independently.

Do not advertise 0.8 as anti-cheat or competition-grade verification.

### Why friend photos are not uploaded yet

Uploading/displaying user photos would turn CapturePilot into a user-generated-content/social-photo service.

Before enabling that feature, CapturePilot should implement at minimum:

- objectionable-content filtering;
- report flow;
- blocking;
- moderation/timely response process;
- published support/contact information;
- appropriate CloudKit or server access controls.

CapturePilot 0.8 intentionally syncs scores, not photos.

---

## Apple Developer / CloudKit setup

The source code can compile before these services are configured, but the social feature cannot be considered physically/TestFlight validated until the Apple Developer resources are ready.

### App ID capabilities

For bundle ID:

```text
com.tiburonns.CapturePilot
```

enable:

- Sign in with Apple;
- iCloud;
- CloudKit.

Container:

```text
iCloud.com.tiburonns.CapturePilot
```

The Xcode target contains matching entitlements.

### Development schema

During development, launch the signed app with the CloudKit development environment and exercise:

1. sign in;
2. profile creation;
3. send friend request;
4. accept friend request;
5. enable score sharing.

This creates/uses the record types.

### Required queryable fields

Before distribution, verify queryable indexes in CloudKit Console for fields used by queries:

**CapturePilotProfile**
- username

**FriendConnection**
- requesterHash
- addresseeHash
- status

**RankingScore**
- ownerHash

Additional indexes may be added for operational/debugging needs, but do not index unused fields without a reason.

### Production deployment

After the development schema is correct:

1. review record types/fields/indexes in CloudKit Console;
2. deploy schema changes to production;
3. verify the distribution provisioning profile includes the Sign in with Apple and iCloud/CloudKit entitlements;
4. test the distributed build with two real accounts/devices.

### Acceptance test

Use two different Apple accounts/devices:

- A signs in and receives a Pilot-* username;
- B signs in and receives a different username;
- A sends B a request;
- B accepts;
- both enable score sharing;
- each captures photos inside CapturePilot;
- verify overall/category leaderboard;
- disable sharing and verify own cloud score records disappear;
- remove friendship and verify the friend disappears from the local leaderboard query scope;
- revoke Sign in with Apple authorization and verify CapturePilot clears the local social session.

---

## Español

### Identidad

CapturePilot **no puede ni intenta leer directamente el Apple ID visible, correo o contraseña**.

Usa **Sign in with Apple**. Apple entrega un identificador opaco `credential.user`.

CapturePilot lo hashea localmente para generar un username automático:

```text
Pilot-A1B2C3D4E5
```

Por tanto, el username queda ligado a la identidad privada que Sign in with Apple entrega a nuestro equipo, no al correo visible del Apple ID.

### CloudKit

La metadata social usa el contenedor:

```text
iCloud.com.tiburonns.CapturePilot
```

en la base pública de CloudKit.

Tipos de registro:

- `CapturePilotProfile`
- `FriendConnection`
- `RankingScore`

### Qué se sincroniza

Cuando la persona activa compartir scores:

- username automático;
- categoría;
- Coach Score;
- fecha.

No se sincronizan en 0.8:

- fotografías;
- miniaturas;
- RAW/JPEG;
- LUT;
- tags;
- recomendaciones;
- correo/nombre/contraseña del Apple ID.

Sólo las fotos tomadas dentro de CapturePilot son elegibles para score social.

### Privacidad de la base pública

La base pública permite descubrimiento de perfiles y comparación.

La metadata sincronizada debe tratarse como **información social pública/pseudónima dentro del servicio**, no como un secreto.

Las fotografías siguen locales.

### No es anti-cheat

El cliente calcula el score.

Aunque restringimos el leaderboard a capturas hechas dentro de CapturePilot, un cliente modificado podría falsear datos.

Para premios o competencias formales haría falta validación confiable del lado servidor.

### Fotos de amigos

0.8 no sube fotos de amigos.

Antes de activar fotos sociales deben existir filtrado, reportes, bloqueo, moderación y contacto de soporte apropiados.

### Configuración Apple requerida

Para `com.tiburonns.CapturePilot`:

- Sign in with Apple;
- iCloud;
- CloudKit;
- contenedor `iCloud.com.tiburonns.CapturePilot`.

En CloudKit Console verifica índices QUERYABLE:

**CapturePilotProfile**
- username

**FriendConnection**
- requesterHash
- addresseeHash
- status

**RankingScore**
- ownerHash

Después despliega el schema probado al entorno de producción antes de considerar lista la función social para distribución.

### Prueba real

Con dos cuentas/dispositivos:

1. login de A;
2. login de B;
3. usernames distintos;
4. solicitud A → B;
5. aceptación;
6. ambos comparten scores;
7. ambos toman fotos en CapturePilot;
8. comparar Overall y categorías;
9. desactivar compartir;
10. eliminar amistad;
11. probar revocación de Sign in with Apple.
