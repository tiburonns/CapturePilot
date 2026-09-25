# Changelog

## 0.3.0 — Adaptive orientation and customizable HUD

### Added
- Landscape-left and landscape-right support.
- Upside-down portrait support.
- Independent switches to disable Landscape or Upside-down portrait.
- RotationCoordinator-based camera preview and capture rotation.
- Persistent HUD layout engine.
- Independent portrait and landscape HUD coordinates.
- Interactive HUD edit mode.
- Safe-area-bounded free dragging.
- Optional HUD item visibility.
- Reset HUD action.
- Real-time edge-contrast Focus Peaking.
- Optional dedicated Focus Peaking quick-access HUD button.
- Expanded bilingual orientation/HUD/peaking documentation.

### Design safeguards
- Standard portrait remains always supported.
- Settings and Shutter cannot be hidden, preventing unrecoverable custom layouts.
- Hidden optional items remain visible as ghosts while editing.
- HUD controls do not execute their normal actions during edit dragging.
- Focus Peaking uses a dedicated button instead of consuming a viewfinder long-press gesture.

### Privacy
- No new network, analytics, account, tracking or cloud behavior.
- New orientation/HUD preferences remain local UserDefaults covered by CA92.1.

## 0.2.0 — TestFlight candidate hardening
- Edge-to-edge camera and safe-area-aware chrome.
- Direct EN/ES/System control.
- AppIcon / launch assets.
- Privacy hardening and Xcode 26 CI.

## 0.1.0 — Initial device-test baseline
- AVFoundation camera.
- Manual controls.
- Capability-gated RAW.
- Initial on-device coach and composition guides.
