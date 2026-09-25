# TestFlight Release Guide / Guía de publicación en TestFlight

## English

### Source status

Version 0.2.0 build 2 is the first TestFlight candidate. The repository contains the app target, AppIcon asset, launch appearance, privacy manifest, localized permissions, English/Spanish/System language controls, and Release configuration. The unsigned Release target has been compiled successfully in GitHub Actions using Xcode 26.6.

A repository can be prepared for TestFlight, but only an archive produced by Xcode on macOS can prove that the binary is accepted by App Store Connect. Do not mark a build as shipped until the archive and upload checks below pass.

### Required environment

- Apple Developer Program membership.
- App record and Bundle ID matching `com.tiburonns.CapturePilot` or the final registered identifier.
- Xcode 26 or later for App Store Connect iOS uploads in 2026.
- A signing team and App Store distribution provisioning managed by Xcode or your organization.

### Archive

1. Pull the latest `main`.
2. Open `CapturePilot.xcodeproj`.
3. Select the CapturePilot target and your paid Developer Team.
4. Confirm the final Bundle Identifier.
5. Use a physical/Generic iOS Device destination.
6. Product > Archive.
7. In Organizer, run Validate App before upload.
8. Resolve every error. Treat warnings as release work unless understood and documented.
9. Distribute App > App Store Connect > Upload.

### App Store Connect / TestFlight

- Confirm version and build are shown as `0.2.0 (2)`.
- Complete export-compliance questions if App Store Connect still requests them. This project declares `ITSAppUsesNonExemptEncryption = NO` because the current source contains no custom/non-exempt encryption.
- Complete Test Information, including beta description, feedback email, and review contact details.
- Start with Internal Testing.
- External testers can be added after the build is eligible; the first externally tested build can require TestFlight App Review.
- Never claim RAW or a specific lens on hardware where CapturePilot hides that capability.

### Gate before external testers

All items in `docs/TESTING.md` and `docs/UI_LAYOUT.md` must pass on at least one Dynamic Island iPhone and one smaller/notched iPhone when available.

## Español

### Estado del código

La versión 0.2.0 build 2 es el primer candidato para TestFlight. El repositorio incluye target de la app, AppIcon, apariencia de inicio, Privacy Manifest, permisos localizados, selector Inglés/Español/Sistema y configuración Release. El target Release sin firma ya compiló correctamente en GitHub Actions con Xcode 26.6.

Preparar el repositorio no demuestra por sí solo que Apple aceptará el binario. Solo un Archive creado con Xcode en macOS y procesado por App Store Connect permite validar esa parte. No marques una compilación como distribuida hasta completar las pruebas siguientes.

### Entorno requerido

- Membresía activa de Apple Developer Program.
- Registro de la app y Bundle ID que coincida con `com.tiburonns.CapturePilot` o el identificador final registrado.
- Xcode 26 o posterior para subir apps iOS a App Store Connect durante 2026.
- Team de firma y distribución App Store configurados en Xcode.

### Archive

1. Actualiza `main`.
2. Abre `CapturePilot.xcodeproj`.
3. Selecciona CapturePilot y tu Team de pago.
4. Confirma el Bundle Identifier final.
5. Selecciona un destino físico/Generic iOS Device.
6. Product > Archive.
7. En Organizer ejecuta Validate App.
8. Corrige todos los errores y revisa cualquier warning.
9. Distribute App > App Store Connect > Upload.

### App Store Connect / TestFlight

- Verifica que aparezca `0.2.0 (2)`.
- Completa export compliance si App Store Connect aún lo solicita. El proyecto declara `ITSAppUsesNonExemptEncryption = NO` porque el código actual no contiene cifrado personalizado/no exento.
- Completa Test Information: descripción beta, correo de feedback y datos de contacto para revisión.
- Empieza por Internal Testing.
- Los testers externos pueden requerir TestFlight App Review, especialmente con el primer build externo.
- No prometas RAW ni una lente concreta en dispositivos donde CapturePilot oculta esa capacidad.

### Puerta antes de testers externos

Deben pasar `docs/TESTING.md` y `docs/UI_LAYOUT.md` al menos en un iPhone con Dynamic Island y, cuando sea posible, otro iPhone pequeño o con notch.
