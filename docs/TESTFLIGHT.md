# TestFlight Release Guide / Guía TestFlight

## English

### Current candidate
- Version: **0.3.0**
- Build: **3**
- CI: Release is compiled against iOS Simulator and iPhoneOS SDKs using Xcode 26.x.
- Remaining gates: physical camera/UI validation, signed Archive, Validate App, App Store Connect processing.

### Physical test priorities
Before external TestFlight distribution, complete:
1. all four orientations while enabled;
2. disabled-orientation behavior;
3. portrait and landscape HUD persistence;
4. Dynamic Island/notch/Home Indicator drag boundaries;
5. Focus Peaking alignment/performance;
6. existing capture/manual-control regression.

Use `docs/TESTING.md` and `docs/UI_LAYOUT.md`.

### Archive
1. Pull latest `main`.
2. Open `CapturePilot.xcodeproj`.
3. Select your paid Developer Team.
4. Confirm final Bundle ID.
5. Test on physical hardware.
6. Product > Archive.
7. Organizer > Validate App.
8. Distribute App > App Store Connect > Upload.
9. Start with Internal Testing.

## Español

### Candidato actual
- Versión: **0.3.0**
- Build: **3**
- CI: Release se compila contra Simulator e iPhoneOS con Xcode 26.x.
- Puertas pendientes: prueba física, Archive firmado, Validate App y procesamiento de App Store Connect.

### Prioridades de prueba física
Antes de TestFlight externo valida:
1. las cuatro orientaciones cuando estén habilitadas;
2. bloqueo de orientaciones desactivadas;
3. persistencia independiente del HUD vertical/horizontal;
4. límites de safe area;
5. alineación/rendimiento de Focus Peaking;
6. regresión de cámara y controles manuales.

Después: Product > Archive, Validate App, Upload y primero Internal Testing.
