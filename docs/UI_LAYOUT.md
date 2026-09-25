# Full-screen UI Validation / Validación de pantalla completa

## English

### Source guarantees

- Preview, composition guides, and Focus Peaking can extend edge-to-edge.
- Functional HUD items are positioned relative to a calculated safe rectangle.
- HUD drag clamps account for each item's measured size.
- Portrait and landscape positions persist independently.
- Settings and shutter cannot be hidden.
- Lens selector scrolls horizontally.
- Standard portrait is always available; landscape and upside-down can be disabled.
- Preview rotation follows `AVCaptureDevice.RotationCoordinator`.
- Capture/video-data rotation uses a separate RotationCoordinator path.

### Physical matrix

#### Dynamic Island

- [ ] No control overlaps the island in portrait.
- [ ] Landscape controls remain reachable.
- [ ] Coach bubble does not become permanently clipped.
- [ ] Scene selector and language controls remain usable.
- [ ] Peaking overlay lines up with the viewfinder.

#### Notched/smaller iPhone

- [ ] Every required HUD control can be reached.
- [ ] Pro controls do not cover the shutter.
- [ ] Lens selector remains scrollable.
- [ ] HUD editing cannot drag required controls outside the safe area.

#### Orientation

- [ ] Portrait → landscape left.
- [ ] Portrait → landscape right.
- [ ] Portrait → upside-down.
- [ ] Rotate while Focus Peaking is enabled.
- [ ] Rotate after switching lenses.
- [ ] Rotate while Pro controls are open.
- [ ] Rotation disabled in Settings is respected.

#### Professional monitoring

- [ ] Zebra overlay matches the exact preview crop.
- [ ] Zebra quick control remains reachable after HUD customization.
- [ ] Compact histogram remains entirely inside the safe area.
- [ ] Expanded histogram clamps inside the safe area.
- [ ] Histogram can be moved in portrait and landscape independently.
- [ ] Histogram expansion does not make Settings/Shutter unreachable.

#### Dynamic Type

- [ ] Default.
- [ ] One larger accessibility size.
- [ ] English.
- [ ] Spanish.
- [ ] HUD customization toolbar remains reachable.

Source inspection cannot certify these physical checks.

---

## Español

### Garantías del código

- Preview, guías y Focus Peaking pueden ocupar toda la pantalla.
- Los controles del HUD se colocan respecto a un rectángulo seguro.
- El clamp considera el tamaño medido de cada elemento.
- Vertical y horizontal guardan posiciones distintas.
- Ajustes y disparador no se pueden ocultar.
- El selector de lentes puede desplazarse.
- Vertical normal siempre existe; horizontal y vertical invertido pueden desactivarse.
- El preview usa `RotationCoordinator`.
- Captura/video-data usan una ruta de rotación separada.

### Matriz física

#### Dynamic Island

- [ ] Ningún control se superpone en vertical.
- [ ] En horizontal todos siguen accesibles.
- [ ] Coach no queda recortado.
- [ ] Escena e idioma son utilizables.
- [ ] Peaking coincide con el preview.

#### iPhone pequeño/notch

- [ ] Controles obligatorios alcanzables.
- [ ] Pro no cubre el disparador.
- [ ] Lentes desplazables.
- [ ] Edición HUD no permite sacar controles obligatorios.

#### Orientación

- [ ] Vertical → horizontal izquierda.
- [ ] Vertical → horizontal derecha.
- [ ] Vertical → invertido.
- [ ] Rotar con Peaking activo.
- [ ] Rotar después de cambiar lente.
- [ ] Rotar con controles Pro abiertos.
- [ ] Ajustes de orientación se respetan.

#### Monitoreo profesional

- [ ] Cebras coinciden con el crop del preview.
- [ ] Control Zebra sigue alcanzable tras personalizar HUD.
- [ ] Histograma compacto permanece dentro del área segura.
- [ ] Histograma ampliado se mantiene dentro del área segura.
- [ ] Posición independiente vertical/horizontal.
- [ ] Expandirlo no vuelve inaccesibles Ajustes/Disparador.

#### Dynamic Type

- [ ] Tamaño normal.
- [ ] Un tamaño grande de accesibilidad.
- [ ] Inglés.
- [ ] Español.
- [ ] Toolbar de HUD accesible.

Estas pruebas no pueden certificarse sólo leyendo el código.
