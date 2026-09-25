# Full-screen, Orientation & HUD Validation / Validación de pantalla, orientación y HUD

## Source behavior / Comportamiento implementado

- Camera preview and composition/peaking overlays fill the display.
- Interactive HUD items are positioned relative to a safe-area rectangle.
- Each item's measured size is included when clamping drag positions.
- Portrait and landscape store different normalized coordinates.
- Upside-down portrait uses the portrait layout with the new safe-area geometry.
- Landscape supports both physical directions when enabled.
- Settings and Shutter remain recoverable and cannot be hidden.
- Focus Peaking quick access is optional and defaults to hidden.

## Dynamic Island
- [ ] No draggable element can be left beneath the island.
- [ ] Rotating from portrait to landscape keeps every visible element reachable.
- [ ] Returning to portrait restores the portrait layout rather than the landscape layout.
- [ ] Upside-down portrait respects the opposite safe-area geometry.

## Small/notched iPhone
- [ ] Lens selector remains movable/reachable.
- [ ] Coach bubble can be placed without clipping.
- [ ] Editor toolbar remains on-screen in portrait and landscape.
- [ ] Manual Pro controls do not make the HUD unrecoverable.

## HUD editing
- [ ] Drag starts without triggering the element's normal action.
- [ ] Drag ends inside the safe area even after a fast throw.
- [ ] Hidden elements can be restored from Elements menu.
- [ ] Reset produces usable portrait and landscape defaults.

## Focus Peaking
- [ ] Overlay uses exactly the camera preview area.
- [ ] Overlay rotation follows the camera in all enabled orientations.
- [ ] Quick button never relies on viewfinder long-press.

## Important

CI verifies compilation, not physical geometry. These checks remain open until tested on hardware.
