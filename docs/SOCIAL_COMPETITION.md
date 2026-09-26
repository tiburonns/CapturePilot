# Friends + Social Scores / Amigos + scores sociales

CapturePilot 0.8 introduces an opt-in social score layer for friendly comparison without uploading friend photos.

---

## English

### Identity: private iCloud-backed CapturePilot identity

CapturePilot does **not** read a person's Apple Account email, password, or account name.

When the photographer explicitly enables Friends Rankings, CapturePilot checks that an iCloud account is available and creates a random social identifier inside that user's **private CloudKit database**.

A fixed private record ID lets the same iCloud account restore the same CapturePilot social identity on another device using the same container.

The automatic username is derived from that random private social identifier, for example:

```text
PILOT-A1B2C3D4E5F6
```

This is the feasible privacy-preserving interpretation of “linked to the Apple ID”: the identity follows the signed-in iCloud/Apple account through its private CloudKit database, while CapturePilot never receives the visible Apple Account identifier.

### CloudKit

Social metadata uses:

```text
iCloud.com.tiburonns.CapturePilot
```

and the container's **public CloudKit database**.

Current record types:

### Private database

#### SocialIdentity

| Field | Type | Purpose |
| --- | --- | --- |
| socialID | String | Random CapturePilot social identifier |
| username | String | Automatic PILOT-* username |
| createdAt | Date | Identity creation |

Only that iCloud account can access the private record by default.

### Public database

#### CapturePilotProfile

| Field | Type | Purpose |
| --- | --- | --- |
| socialID | String | Random pseudonymous CapturePilot social identity |
| username | String | Automatic PILOT-* username |
| createdAt | Date | Profile creation |

#### FriendRequest

| Field | Type |
| --- | --- |
| requesterID | String |
| requesterUsername | String |
| addresseeID | String |
| createdAt | Date |

The requester owns this public record.

#### FriendAcceptance

| Field | Type |
| --- | --- |
| requestRecordName | String |
| requesterID | String |
| addresseeID | String |
| active | Bool/Int |
| updatedAt | Date |

The addressee creates/owns the acceptance record. This avoids requiring one user to modify another user's CloudKit record.

#### RankingScore

| Field | Type |
| --- | --- |
| ownerID | String |
| username | String |
| category | String |
| score | Double |
| capturedAt | Date |
| scoreVersion | Int | Ranking formula version |

CapturePilot stores at most one current best-score record per user/category record ID.

### Friend flow

1. Enable Friends Rankings while signed into iCloud.
2. CapturePilot creates/restores the private SocialIdentity.
3. A minimal public profile exposes only the automatic username/social ID.
4. Search/add by exact CapturePilot username.
5. Requester creates a FriendRequest.
6. Addressee accepts by creating their own FriendAcceptance record.
7. Accepted users appear in the friends list.
8. The leaderboard contains the current user's and accepted friends' shared best scores.

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

- iCloud;
- CloudKit.

Container:

```text
iCloud.com.tiburonns.CapturePilot
```

The Xcode target contains matching entitlements.

### Development schema

During development, launch the signed app with the CloudKit development environment and exercise:

1. enable Friends Rankings with an available iCloud account;
2. private SocialIdentity + public profile creation;
3. send friend request;
4. accept friend request;
5. enable score sharing.

This creates/uses the record types.

### Required queryable fields

Before distribution, verify queryable indexes in CloudKit Console for fields used by queries:

**CapturePilotProfile**
- username

**FriendRequest**
- requesterID
- addresseeID

**RankingScore**
- ownerID

Additional indexes may be added for operational/debugging needs, but do not index unused fields without a reason.

### Production deployment

After the development schema is correct:

1. review record types/fields/indexes in CloudKit Console;
2. deploy schema changes to production;
3. verify the distribution provisioning profile includes the iCloud/CloudKit entitlements;
4. test the distributed build with two real accounts/devices.

### Acceptance test

Use two different Apple accounts/devices:

- A enables Friends and receives a PILOT-* username;
- B enables Friends and receives a different username;
- A sends B a request;
- B accepts;
- both enable score sharing;
- each captures photos inside CapturePilot;
- verify overall/category leaderboard;
- disable sharing and verify own cloud score records disappear;
- remove friendship and verify the friend disappears from the local leaderboard query scope;
- sign out of iCloud / test unavailable account state and verify the social layer fails gracefully while local Rankings keep working.

---

## Español

### Identidad

CapturePilot **no puede ni intenta leer directamente el Apple ID visible, correo o contraseña**.

Al activar Amigos, CapturePilot verifica una cuenta iCloud disponible y crea un identificador social aleatorio dentro de la **base privada de CloudKit** de esa cuenta.

El username automático se deriva de esa identidad privada:

```text
PILOT-A1B2C3D4E5F6
```

Así la identidad puede seguir a la misma cuenta iCloud entre dispositivos sin que CapturePilot reciba correo, contraseña o nombre visible de la cuenta Apple.

### CloudKit

La metadata social usa el contenedor:

```text
iCloud.com.tiburonns.CapturePilot
```

en la base pública de CloudKit.

Tipos de registro:

**Privado**
- `SocialIdentity`

**Público**
- `CapturePilotProfile`
- `FriendRequest`
- `FriendAcceptance`
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
- correo/nombre/contraseña de la cuenta Apple.

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

- iCloud;
- CloudKit;
- contenedor `iCloud.com.tiburonns.CapturePilot`.

En CloudKit Console verifica índices QUERYABLE:

**CapturePilotProfile**
- username

**FriendRequest**
- requesterID
- addresseeID

**RankingScore**
- ownerID

Después despliega el schema probado al entorno de producción antes de considerar lista la función social para distribución.

### Prueba real

Con dos cuentas/dispositivos:

1. A activa Amigos con iCloud disponible;
2. B activa Amigos con otra cuenta iCloud;
3. usernames distintos;
4. solicitud A → B;
5. aceptación;
6. ambos comparten scores;
7. ambos toman fotos en CapturePilot;
8. comparar Overall y categorías;
9. desactivar compartir;
10. eliminar amistad;
11. probar cierre/no disponibilidad de iCloud sin romper el ranking local.
