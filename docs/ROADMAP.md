# Roadmap / Hoja de ruta

The roadmap distinguishes source implementation, physical validation and future work.

## 0.1 — Camera + coach baseline
- [x] AVFoundation preview/capture
- [x] HEIF/JPEG
- [x] Capability-gated RAW
- [x] Lens discovery/switching
- [x] EV / ISO / shutter / focus / white balance
- [x] Tap-to-focus / meter
- [x] Basic on-device coach
- [x] Composition guides
- [x] English / Spanish / System
- [x] Privacy Manifest

## 0.2 — TestFlight hardening
- [x] Edge-to-edge camera
- [x] Safe-area-aware controls
- [x] AppIcon / launch assets
- [x] CA92.1 UserDefaults declaration
- [x] Bilingual release documentation
- [x] Xcode 26 Release CI for Simulator and iPhoneOS

## 0.3 — Adaptive orientation + HUD
- [x] Landscape-left/right source support
- [x] Upside-down portrait source support
- [x] Independent Landscape / Upside-down enable switches
- [x] AVFoundation RotationCoordinator for preview/capture rotation
- [x] Persistent portrait/landscape HUD layouts
- [x] Safe-area-bounded drag editing
- [x] Optional show/hide HUD elements
- [x] Recovery-safe required Settings/Shutter
- [x] Reset HUD
- [x] Edge-contrast Focus Peaking implementation
- [x] Optional quick Focus Peaking HUD toggle
- [ ] Physical rotation matrix passed
- [ ] HUD dragging validated on Dynamic Island + small/notched iPhone
- [ ] Focus Peaking alignment/performance validated on physical camera

## 0.4 — Exposure tools
Planned:
- [ ] Zebra overlay
- [ ] Luminance/RGB histogram
- [ ] Peaking threshold/color customization
- [ ] Expanded device capability report

## 0.5 — Composition intelligence
Planned:
- [ ] Leading-line detection
- [ ] Symmetry analysis
- [ ] Vanishing-point estimation
- [ ] Negative-space analysis
- [ ] Golden triangle / spiral
- [ ] Better multi-subject grouping

## 0.6 — Scene coaches
Planned:
- [ ] Portrait
- [ ] Architecture
- [ ] Automotive
- [ ] Macro
- [ ] Street
- [ ] Landscape
- [ ] Night

## Later professional capture
Planned:
- [ ] ProRAW-specific workflow
- [ ] Bracketing
- [ ] Dedicated AF/AE long-press lock
- [ ] Capture stability/readiness
- [ ] Metadata review
- [ ] Optional post-capture teaching review

## Principle / Principio

Implemented means source exists and compiles. Device-validated means the physical-device checklist passed. TestFlight-processed means App Store Connect accepted the uploaded build.

Implementado significa que existe código y compila. Validado significa que pasó la prueba física. Procesado por TestFlight significa que App Store Connect aceptó el build.
