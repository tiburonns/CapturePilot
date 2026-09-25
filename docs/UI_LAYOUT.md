# Full-screen UI Validation / Validación de pantalla completa

## What the source now guarantees / Qué garantiza el código

- The camera preview explicitly ignores safe areas and fills the display behind the Dynamic Island/notch and Home Indicator.
- Camera controls remain inside safe-area-aware layout.
- The status bar is hidden in SwiftUI and during launch.
- System overlays are requested hidden while shooting.
- The top control row is separated from the lens selector to avoid horizontal compression on smaller iPhones.
- The lens selector scrolls horizontally instead of forcing buttons outside the screen.
- Bottom capture controls keep safe-area padding and do not intentionally overlap the Home Indicator.
- Orientation is intentionally portrait-only for this TestFlight candidate.

## Physical-device matrix / Matriz de prueba física

### Dynamic Island
- [ ] Viewfinder reaches all four display edges.
- [ ] No black rectangle/pillarbox appears around the camera preview.
- [ ] Pro, language and settings buttons do not touch/overlap Dynamic Island.
- [ ] Lens selector remains fully reachable.
- [ ] Coach bubble never becomes clipped by the island.

### Smaller/notched iPhone
- [ ] Top buttons remain on-screen at default text size.
- [ ] Lens selector scrolls rather than overflowing.
- [ ] Shutter and format/grid buttons remain above the Home Indicator.
- [ ] Opening Pro controls does not push the shutter off-screen.

### Accessibility layout
- [ ] Test standard and at least one larger Dynamic Type size.
- [ ] Settings screen remains navigable in English and Spanish.
- [ ] Language button remains reachable after switching languages.

## Important

These checks cannot be certified from source inspection alone. They must be completed on hardware before external TestFlight distribution.
