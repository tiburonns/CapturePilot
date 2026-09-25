# Architecture / Arquitectura

## English

CapturePilot 0.3.0 separates camera capture, analysis, HUD state, app settings and presentation.

```text
CapturePilot
├── Camera
│   ├── CameraModels.swift
│   ├── CameraPreview.swift
│   ├── CameraService.swift
│   └── FocusPeakingEngine.swift
├── Coach
│   ├── CoachModels.swift
│   └── CoachEngine.swift
├── HUD
│   ├── HUDLayout.swift
│   └── HUDMovableItem.swift
├── Settings
│   ├── AppSettings.swift
│   ├── OrientationPolicy.swift
│   └── SettingsView.swift
├── UI
│   ├── CoachBubble.swift
│   ├── CompositionOverlay.swift
│   ├── FocusPeakingOverlay.swift
│   └── ManualControlsView.swift
├── ContentView.swift
└── CapturePilotApp.swift
```

### Orientation

The Info.plist advertises portrait, portrait upside-down and both landscape orientations. `OrientationPolicy` then restricts the runtime mask using the user's Landscape and Upside-down settings while always retaining standard portrait.

When the preference changes, the app asks connected window scenes to refresh their supported orientations and requests compatible scene geometry.

AVFoundation rotation is separate from interface rotation. `AVCaptureDevice.RotationCoordinator` supplies the angle for both preview and capture/video-data connections so the camera stream can remain level across orientation changes.

### HUD

`HUDLayoutStore` persists a normalized position for every HUD item. Each item has:
- visibility;
- portrait coordinates;
- landscape coordinates.

Coordinates are relative to the current safe rectangle rather than raw pixels. This allows a saved layout to adapt to different screen sizes and cutouts.

`HUDMovableItem` measures its own view size and clamps its center so the item remains inside the safe area. While editing, functional controls stop receiving their normal tap behavior and the wrapper owns the drag gesture.

Settings and the shutter are intentionally non-hideable. This is a recovery constraint: the user can freely customize the rest of the HUD without creating a camera UI that cannot reach Settings or capture a photo.

### Focus Peaking

`FocusPeakingEngine` only runs when requested. It reads the Y/luminance plane of the existing video-data output, calculates local horizontal/vertical gradients on a downsampled grid, and emits a transparent red/orange CGImage for pixels above the edge threshold.

This is an edge-contrast focus aid. It is not documented as an absolute physical focus-confidence measurement.

The overlay is rendered independently from the camera preview. The optional HUD button toggles it with a tap, leaving the viewfinder free of a long-press peaking gesture.

### Camera and coach

`CameraService` owns AVFoundation, photo capture, manual controls, rotation coordination, coach delivery and optional peaking delivery. Frames remain on the existing serial video-output queue.

`CoachEngine` continues to use Vision and sampled luminance for composition/technical guidance.

### Persistence/privacy

Language, grid, coach mode, orientation switches and HUD layout are all app-local preferences stored with UserDefaults. They remain covered by the existing Privacy Manifest CA92.1 declaration.

No new network service, account, tracking, analytics or cloud upload was added in 0.3.0.

---

## Español

CapturePilot 0.3.0 separa captura, análisis, estado del HUD, ajustes y presentación.

### Orientación

Info.plist permite vertical normal, vertical invertido y ambas orientaciones horizontales. `OrientationPolicy` restringe en ejecución las orientaciones según los interruptores del usuario, manteniendo siempre vertical normal.

AVFoundation utiliza `AVCaptureDevice.RotationCoordinator` para ajustar preview y conexiones de captura independientemente de la rotación de la interfaz.

### HUD

`HUDLayoutStore` guarda visibilidad y coordenadas normalizadas para cada elemento, con posiciones independientes para vertical y horizontal.

`HUDMovableItem` mide el tamaño de cada control y limita el arrastre para que permanezca dentro del área segura. Durante edición, los controles no ejecutan su acción normal.

Ajustes y disparador no se pueden ocultar para garantizar que siempre exista una ruta de recuperación.

### Focus Peaking

`FocusPeakingEngine` procesa únicamente cuando está activado. Usa el plano de luminancia, calcula gradientes locales y genera un overlay transparente rojo/naranja para bordes de alto contraste.

Es una ayuda de enfoque basada en contraste de bordes, no una medición absoluta del plano focal.

### Persistencia/privacidad

Idioma, guía, coach, orientación y layout HUD se almacenan localmente con UserDefaults. No se agregó red, cuenta, tracking, analítica ni subida a la nube.
