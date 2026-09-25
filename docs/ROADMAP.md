# Roadmap / Hoja de ruta

The roadmap distinguishes implemented source, device validation, and future ideas. A checked source item is not equivalent to a successfully processed TestFlight build.

## 0.1 — Camera + coach baseline

- [x] AVFoundation preview and capture
- [x] HEIF/JPEG
- [x] RAW only when the active device/configuration reports support
- [x] Lens discovery and switching
- [x] EV / ISO / shutter / focus / white balance
- [x] Tap-to-focus and tap-to-meter
- [x] Horizon / person / saliency / sampled-luminance coach
- [x] Thirds / golden-ratio / crosshair guides
- [x] English / Spanish / System language setting
- [x] Privacy Manifest

## 0.2 — TestFlight candidate hardening

- [x] Edge-to-edge camera preview
- [x] Safe-area-aware camera controls
- [x] Hidden shooting status bar / launch status bar
- [x] Compact top chrome for smaller iPhones
- [x] Direct language button in the camera UI
- [x] AppIcon asset catalog
- [x] Launch-screen background asset
- [x] UserDefaults Required Reason API declaration (CA92.1)
- [x] Export-compliance Info.plist declaration for current no-custom-encryption source
- [x] Version/build set to 0.2.0 (2)
- [x] Bilingual TestFlight, privacy, UI and testing documentation
- [x] CI build workflow added
- [ ] Physical-device checklist passed
- [ ] Xcode 26 Release archive validated
- [ ] Build uploaded and processed successfully by App Store Connect

## 0.3 — Exposure and focus tools

Planned, not currently advertised as implemented:

- [ ] Real-time histogram
- [ ] Zebra overlay
- [ ] Focus peaking
- [ ] Expanded device capability report

## 0.4 — Composition intelligence

Planned:

- [ ] Leading-line detection
- [ ] Symmetry analysis
- [ ] Vanishing-point estimation
- [ ] Negative-space analysis
- [ ] Golden triangle and spiral overlays
- [ ] Better multi-subject grouping

## 0.5 — Scene coaches

Planned:

- [ ] Portrait
- [ ] Architecture
- [ ] Automotive
- [ ] Macro
- [ ] Street
- [ ] Landscape
- [ ] Night

A scene mode will not be exposed until it changes real analysis rules.

## Later professional capture work

Planned:

- [ ] Apple ProRAW workflow where supported
- [ ] Bracketing workflows
- [ ] Capture stabilization/readiness assistance
- [ ] Metadata review
- [ ] Optional post-capture teaching review

## Principle / Principio

A feature is documented as implemented only when code exists. A feature is documented as device-validated only after a physical test. A release is documented as TestFlight-processed only after App Store Connect accepts the uploaded binary.

Una función se documenta como implementada solo cuando existe código. Se documenta como validada en dispositivo solo después de una prueba física. Una versión se documenta como procesada por TestFlight solo después de que App Store Connect acepte el binario.
