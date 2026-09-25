# Device Test Checklist / Lista de prueba en dispositivo

Use a physical iPhone. Record the model, iOS version, Xcode version, and any console error before changing code.

## 1. Launch / Inicio

- [ ] App installs and launches.
- [ ] Camera permission appears in the device language.
- [ ] Denying camera permission shows the recovery screen and Settings button.
- [ ] Granting permission produces a live rear-camera preview.

## 2. Lenses / Lentes

- [ ] 0.5× appears only when Ultra Wide exists.
- [ ] 1× appears and works.
- [ ] Tele appears only when a telephoto camera exists.
- [ ] Switching lenses does not freeze the preview.
- [ ] Manual state resets cleanly after a lens change.

## 3. Focus and exposure / Enfoque y exposición

- [ ] Tapping the preview shows the focus reticle.
- [ ] Tap-to-focus visibly refocuses between near/far subjects.
- [ ] EV adjustment changes preview exposure.
- [ ] Manual exposure toggle works.
- [ ] ISO changes in manual mode.
- [ ] Shutter duration changes in manual mode.
- [ ] Manual focus changes lens position.
- [ ] Returning to AF works.
- [ ] Manual white balance changes color temperature.
- [ ] Returning to AWB works.

## 4. Capture / Captura

- [ ] HEIF captures and saves.
- [ ] JPEG captures and saves.
- [ ] RAW is shown only when supported.
- [ ] RAW capture saves a valid asset when shown.
- [ ] Photo Library permission is localized.
- [ ] Save success/failure banner matches the result.

## 5. Coach

- [ ] Tilting the phone several degrees triggers level guidance.
- [ ] Strong overexposure triggers highlight guidance.
- [ ] Very dark scenes trigger low-light guidance.
- [ ] A person/face is detected reliably in ordinary light.
- [ ] Balanced mode provides compositional guidance.
- [ ] Subtle mode avoids noncritical composition prompts.
- [ ] Teaching mode displays secondary explanations/subject marker.
- [ ] Messages remain stable instead of changing every frame.

## 6. Language / Idioma

- [ ] System follows Spanish system language.
- [ ] System follows English system language.
- [ ] Forced English updates the UI immediately.
- [ ] Forced Spanish updates the UI immediately.
- [ ] Language selection persists after relaunch.
- [ ] Grid and coach settings persist after relaunch.

## Report format / Formato de reporte

```text
Device:
iOS:
Xcode:
Build result:
Failed checklist item:
Expected:
Observed:
Console error:
Screenshot/video:
```
