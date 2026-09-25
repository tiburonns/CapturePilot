# TestFlight Release Guide / Guía de publicación en TestFlight

## English

### Candidate

CapturePilot 0.3.0 build 3 compiles in Release for iOS Simulator and iPhoneOS in GitHub Actions.

The candidate includes capability-driven HEIF/RAW/ProRAW, maximum photo dimensions, resolution selection, adaptive physical lens switching, manual controls, local geometric coaching, eight scene coach modes, adaptive orientation, customizable HUD, and Focus Peaking.

Compilation does not prove physical camera behavior or App Store acceptance.

### Before Archive

Complete the physical checklists in:

- `docs/TESTING.md`
- `docs/UI_LAYOUT.md`

At minimum use:

- one recent Pro iPhone capable of ProRAW/high-resolution capture;
- one smaller/notched or otherwise different-layout iPhone when available.

Record actual dimensions for every resolution shown.

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

- Confirm **0.3.0 (3)**.
- Complete export compliance as requested.
- Fill beta description, feedback contact, and review contact.
- Start with Internal Testing.
- Verify HEIF/JPEG/RAW/ProRAW labels match actual output on the test hardware.
- Do not advertise 24/48 MP, ProRAW, telephoto, or manual modes on devices where CapturePilot does not expose those capabilities.

---

## Español

### Candidato

CapturePilot 0.3.0 build 3 compila en Release para Simulator e iPhoneOS mediante GitHub Actions.

Incluye HEIF/RAW/ProRAW condicionados por capability, dimensiones máximas, selector de resolución, lentes físicas, controles manuales, análisis geométrico local, ocho coaches de escena, orientación adaptativa, HUD y Focus Peaking.

Compilar no demuestra comportamiento físico ni aceptación de App Store.

### Antes del Archive

Completa:

- `docs/TESTING.md`
- `docs/UI_LAYOUT.md`

Usa al menos un iPhone Pro reciente capaz de ProRAW/alta resolución y, cuando sea posible, otro modelo con geometría de pantalla distinta.

Registra las dimensiones reales de cada resolución mostrada.

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

- Confirma **0.3.0 (3)**.
- Completa export compliance.
- Completa descripción beta y contactos.
- Empieza con Internal Testing.
- Comprueba que HEIF/JPEG/RAW/ProRAW coincidan con el archivo real.
- No anuncies 24/48 MP, ProRAW, telefoto o controles manuales en hardware donde CapturePilot no los exponga.
