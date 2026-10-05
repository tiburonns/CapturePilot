# Optional CloudKit build / Compilación opcional con CloudKit

CapturePilot 0.9.3 changes the social architecture so iCloud/CloudKit is **not required to launch or use the core app**.

## Default build

The repository now defaults to a Personal-Team-compatible build:

- no `CODE_SIGN_ENTITLEMENTS` is attached to the target;
- `CAPTUREPILOT_CLOUDKIT` is not defined;
- `CKContainer` is never created;
- Friends Rankings is hidden;
- camera, Coach, Creative Spark, LUT library, RAW+Share JPEG and private Rankings remain available.

This prevents a missing iCloud entitlement from crashing the app before the first screen appears.

## Enabling Friends later

When an Apple Developer setup with iCloud/CloudKit is available:

1. Enable **iCloud + CloudKit** for `com.tiburonns.CapturePilot`.
2. Add/use container:
   `iCloud.com.tiburonns.CapturePilot`
3. Attach:
   `CapturePilot/CapturePilot.entitlements`
   as the target's Code Signing Entitlements file.
4. Add the Swift Active Compilation Condition:
   `CAPTUREPILOT_CLOUDKIT`
5. Replace/update the bundled `CapturePilot/PrivacyInfo.xcprivacy` using `docs/PrivacyInfo.CloudKit.xcprivacy.template`.
6. Regenerate/download a provisioning profile that contains the iCloud/CloudKit entitlements.
7. Build and test the social flow on a real device.
8. Configure/deploy the required CloudKit schema/indexes before TestFlight distribution.
9. Make App Store Connect App Privacy answers match the CloudKit-enabled binary.

If any of these pieces are missing, keep the flag off.

## Runtime behavior

Even in a CloudKit-enabled build, Friends remains opt-in.

In a build without the compile condition:
- stale social preferences are reset;
- score sharing is forced off;
- social methods return safely;
- the Friends control is hidden from Rankings.

---

## Español

CapturePilot 0.9.3 hace que iCloud/CloudKit **no sea necesario para abrir ni usar la aplicación principal**.

### Build por defecto

El repo queda compatible con Personal Team:

- el target no usa `CODE_SIGN_ENTITLEMENTS`;
- no existe la condición `CAPTUREPILOT_CLOUDKIT`;
- nunca se crea `CKContainer`;
- Amigos queda oculto;
- cámara, Coach, Chispa creativa, LUTs, RAW+Share y Ranking privado siguen disponibles.

Esto evita que un entitlement iCloud ausente cierre la app antes de mostrar la primera pantalla.

### Activar Amigos después

Cuando exista una configuración Apple Developer compatible:

1. Activa **iCloud + CloudKit** para `com.tiburonns.CapturePilot`.
2. Usa el contenedor `iCloud.com.tiburonns.CapturePilot`.
3. Configura `CapturePilot/CapturePilot.entitlements` como Code Signing Entitlements.
4. Agrega `CAPTUREPILOT_CLOUDKIT` a Swift Active Compilation Conditions.
5. Actualiza/reemplaza `CapturePilot/PrivacyInfo.xcprivacy` usando `docs/PrivacyInfo.CloudKit.xcprivacy.template`.
6. Usa un provisioning profile con esos entitlements.
7. Prueba en un dispositivo real.
8. Configura y despliega schema/índices antes de TestFlight.
9. Alinea App Privacy de App Store Connect con el binario CloudKit.

Si falta cualquiera de estos pasos, deja la flag desactivada.
