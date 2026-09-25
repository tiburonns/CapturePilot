# Device Test Checklist / Lista de prueba en dispositivo

Record iPhone model, iOS version, Xcode version and CapturePilot version/build.

## 1. Build / Inicio
- [ ] Release builds with Xcode 26 or later.
- [ ] App installs and launches.
- [ ] Camera/Photos permission flows work.

## 2. Orientation / Orientación

With Landscape ON and Upside-down ON:
- [ ] Portrait works.
- [ ] Portrait upside-down rotates and remains usable.
- [ ] Landscape left works.
- [ ] Landscape right works.
- [ ] Preview remains correctly oriented after each rotation.
- [ ] Captured JPEG/HEIF is stored with correct orientation.
- [ ] RAW capture, when exposed, has correct orientation metadata/content.

Disable Landscape:
- [ ] Device no longer settles into landscape UI.
- [ ] If currently landscape, returning to an allowed orientation is handled cleanly.

Disable Upside-down:
- [ ] Device no longer settles into upside-down portrait.
- [ ] Standard portrait remains available in every setting combination.

## 3. HUD editor / Editor HUD
- [ ] Settings > Customize HUD returns to camera in edit mode.
- [ ] Every HUD item can be dragged.
- [ ] Elements cannot be dragged under Dynamic Island/notch.
- [ ] Elements cannot be dragged under Home Indicator unsafe area.
- [ ] Portrait positions persist after relaunch.
- [ ] Landscape positions persist independently.
- [ ] Rotating does not overwrite the other layout.
- [ ] Optional elements can be hidden.
- [ ] Hidden elements appear as editable ghosts while editing.
- [ ] Settings cannot be hidden.
- [ ] Shutter cannot be hidden.
- [ ] Reset HUD restores defaults.
- [ ] Normal control actions do not fire while dragging/editing.

## 4. Focus Peaking
- [ ] Enable Focus Peaking quick access from HUD editor.
- [ ] Quick button appears near its saved edge position.
- [ ] One tap enables peaking; second tap disables it.
- [ ] No long press is required.
- [ ] Tap-to-focus continues to work independently when not editing.
- [ ] Peaking overlay aligns with the preview in portrait.
- [ ] Peaking overlay aligns in both landscape directions.
- [ ] Peaking overlay aligns upside-down.
- [ ] High-detail/in-focus edges receive substantially more highlighting than smooth/out-of-focus regions.
- [ ] Enabling peaking does not cause unacceptable camera stutter or thermal load during a short smoke test.

## 5. Existing camera regression
- [ ] 0.5× only when available.
- [ ] 1× works.
- [ ] Tele only when available.
- [ ] HEIF saves.
- [ ] JPEG saves.
- [ ] RAW appears/saves only when supported.
- [ ] EV/ISO/shutter work.
- [ ] AF/manual focus work.
- [ ] AWB/manual white balance work.
- [ ] Coach remains stable.

## 6. Language / Idioma
- [ ] AUTO/System.
- [ ] English.
- [ ] Español.
- [ ] New Orientation and HUD labels change language immediately.
- [ ] Language persists.

## 7. TestFlight gate
- [ ] Simulator Release CI passes.
- [ ] iPhoneOS Release CI passes.
- [ ] Product > Archive succeeds signed.
- [ ] Validate App succeeds.
- [ ] Internal TestFlight build processes and installs.
- [ ] Physical smoke test passes before external beta.

## Report format

Device:
iOS:
Xcode:
CapturePilot version/build:
Orientation settings:
Build result:
Failed item:
Expected:
Observed:
Console error:
Screenshot/video:
