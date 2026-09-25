# Architecture / Arquitectura

## English

CapturePilot 0.1 is intentionally small and modular.

```text
CapturePilot
├── Camera
│   ├── CameraModels.swift
│   ├── CameraPreview.swift
│   └── CameraService.swift
├── Coach
│   ├── CoachModels.swift
│   └── CoachEngine.swift
├── Settings
│   ├── AppSettings.swift
│   └── SettingsView.swift
├── UI
│   ├── CoachBubble.swift
│   ├── CompositionOverlay.swift
│   └── ManualControlsView.swift
├── ContentView.swift
└── CapturePilotApp.swift
```

### Camera layer

`CameraService` owns the AVFoundation capture session, device inputs, photo output, video-frame output, manual camera settings, capture formats, and Photos save flow. Camera configuration runs on a dedicated serial queue.

`CameraPreview` is a thin `UIViewRepresentable` around `AVCaptureVideoPreviewLayer`. It also converts screen taps into capture-device coordinates for real tap-to-focus/metering.

### Coach layer

`CoachEngine` receives throttled video frames and performs Vision requests off the main thread. It currently combines horizon, people/faces, saliency, and sampled luminance into a single prioritized recommendation.

The coach deliberately returns a recommendation rather than a numerical "photo score." Composition is contextual and creative; the system should explain opportunities without pretending there is one objectively perfect frame.

### UI layer

SwiftUI owns presentation. Pro controls call `CameraService`; composition overlays consume coach state; settings are persisted through `UserDefaults`.

### Privacy boundary

No frame is uploaded by this baseline. Camera frames are processed in memory by local Apple frameworks. Photo bytes are written to the user's Photo Library only after capture and authorization.

## Español

CapturePilot 0.1 mantiene una arquitectura pequeña y modular. `CameraService` concentra AVFoundation y el guardado; `CoachEngine` analiza frames fuera del hilo principal; SwiftUI presenta el visor, controles y recomendaciones.

El coach devuelve recomendaciones priorizadas, no una puntuación estética. La composición depende del contexto y de la intención del fotógrafo.

En esta base ningún frame se sube a un servidor. El análisis ocurre en memoria y las fotografías se escriben en la fototeca únicamente después de la captura y autorización.
