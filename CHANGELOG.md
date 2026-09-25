# Changelog

## 0.2.0 — TestFlight candidate hardening

### Added
- Direct System / English / Spanish language menu in the camera UI.
- Safe-area-aware full-screen camera chrome.
- AppIcon asset catalog with a 1024×1024 source icon.
- Dark launch-screen asset.
- TestFlight, privacy, full-screen UI, testing, and metadata documentation.
- Release-build CI workflow.

### Changed
- Top camera controls and lens selector are separated to reduce overflow on smaller iPhones.
- Lens selector can scroll horizontally.
- App version/build is now 0.2.0 (2).
- README and roadmap now explicitly separate implemented, device-validated, planned, and distribution-validated states.

### Privacy / distribution
- Added UserDefaults Required Reason API declaration with CA92.1.
- Added `ITSAppUsesNonExemptEncryption = NO` for the current source.
- Status bar is hidden for the shooting UI and launch.
- Current source still contains no account, ads, third-party analytics, or CapturePilot cloud upload.

## 0.1.0 — Initial device-test baseline

### Added
- Native SwiftUI/AVFoundation camera foundation.
- HEIF/JPEG and capability-gated RAW capture.
- Ultra Wide/Wide/Tele discovery and switching.
- Tap-to-focus and exposure metering.
- EV, ISO, shutter, manual focus, and white-balance controls.
- On-device Vision coach for horizon, people/faces, saliency, and exposure conditions.
- Coach message stabilization and three guidance levels.
- Rule-of-thirds, golden-ratio, crosshair, and level overlays.
- English, Spanish, and System language modes with persistent preferences.
- Localized permission strings and Privacy Manifest.
