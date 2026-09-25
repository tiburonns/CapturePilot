# Device Test Checklist / Lista de prueba en dispositivo

Use a physical iPhone. Record model, iOS version, Xcode version, app version/build, and console errors before changing code.

## 1. Build and launch / Compilación e inicio

- [ ] Release configuration builds with Xcode 26 or later.
- [ ] App installs and launches.
- [ ] App icon is present in the Home Screen/TestFlight build.
- [ ] Launch transition uses the dark CapturePilot background without a white flash.
- [ ] Camera permission appears in the device language.
- [ ] Denying permission shows the recovery screen and Settings button.
- [ ] Granting permission produces a live rear-camera preview.

## 2. Full screen / Pantalla completa

- [ ] Viewfinder fills the display edge-to-edge.
- [ ] No unintended black frame/pillarbox appears.
- [ ] Status bar is hidden while shooting.
- [ ] Dynamic Island/notch does not cover camera controls.
- [ ] Home Indicator area does not cover shutter/format/grid controls.
- [ ] Lens selector remains usable on a smaller iPhone.
- [ ] Pro controls do not push primary capture controls off-screen.

See `docs/UI_LAYOUT.md`.

## 3. Lenses / Lentes

- [ ] 0.5× appears only when Ultra Wide exists.
- [ ] 1× appears and works.
- [ ] Tele appears only when a telephoto camera exists.
- [ ] Switching lenses does not freeze the preview.
- [ ] Manual state resets cleanly after lens change.

## 4. Focus and exposure / Enfoque y exposición

- [ ] Tapping preview shows focus reticle.
- [ ] Tap-to-focus visibly refocuses between near/far subjects.
- [ ] EV adjustment changes preview exposure.
- [ ] Manual exposure toggle works.
- [ ] ISO changes in manual mode.
- [ ] Shutter duration changes in manual mode.
- [ ] Manual focus changes lens position.
- [ ] Returning to AF works.
- [ ] Manual white balance changes color temperature.
- [ ] Returning to AWB works.

## 5. Capture / Captura

- [ ] HEIF captures and saves.
- [ ] JPEG captures and saves.
- [ ] RAW is shown only when supported.
- [ ] RAW capture saves a valid asset when shown.
- [ ] Photo Library permission is localized.
- [ ] Save success/failure banner matches result.

## 6. Coach

- [ ] Tilting several degrees triggers level guidance.
- [ ] Strong overexposure triggers highlight guidance.
- [ ] Very dark scenes trigger low-light guidance.
- [ ] A person/face is detected reliably in ordinary light.
- [ ] Balanced mode provides compositional guidance.
- [ ] Subtle mode avoids noncritical prompts.
- [ ] Teaching mode displays secondary explanation/subject marker.
- [ ] Messages remain stable instead of changing every frame.

## 7. Language / Idioma

- [ ] Globe button is visible from the camera.
- [ ] Globe menu offers System, English and Spanish.
- [ ] System follows Spanish device language.
- [ ] System follows English device language.
- [ ] Forced English updates camera/settings UI immediately.
- [ ] Forced Spanish updates camera/settings UI immediately.
- [ ] Settings language selector matches the globe selection.
- [ ] Language selection persists after relaunch.
- [ ] Grid and coach preferences persist after relaunch.
- [ ] Camera/Photo permission strings are localized by iOS.

## 8. Distribution / Distribución

- [ ] Product > Archive succeeds using Release.
- [ ] Organizer > Validate App succeeds.
- [ ] Version/build is 0.2.0 (2).
- [ ] App Store Connect processes the upload without binary/privacy/icon errors.
- [ ] Internal TestFlight install launches and captures a photo.
- [ ] Crash-free smoke test completed before external beta.

## Report format / Formato de reporte

Device:
iOS:
Xcode:
CapturePilot version/build:
Build result:
Failed checklist item:
Expected:
Observed:
Console error:
Screenshot/video:
