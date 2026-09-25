# Architecture / Arquitectura

## English

CapturePilot 0.2.0 is organized so camera capture, scene analysis, presentation, settings, and distribution metadata can evolve independently.

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
├── Assets.xcassets
├── en.lproj / es.lproj
├── PrivacyInfo.xcprivacy
├── Info.plist
├── ContentView.swift
└── CapturePilotApp.swift
```

### Camera layer

`CameraService` owns the AVFoundation session, camera inputs, photo output, video-frame output, device capability discovery, manual camera controls, capture formats, and add-only Photos save flow. Session mutations run on a dedicated serial queue.

`CameraPreview` wraps `AVCaptureVideoPreviewLayer` with `.resizeAspectFill`, converts view taps to capture-device coordinates, displays the focus reticle, and uses the iOS 17+ video-rotation-angle API for portrait capture.

### Full-screen boundary

The preview and composition overlay extend under display cutouts and the Home Indicator. Interactive controls do not intentionally use those unsafe regions: the camera chrome uses SwiftUI safe-area padding, the top controls are split from the lens selector, and the lens selector can scroll horizontally on narrow displays.

The shooting view hides the status bar and requests persistent system overlays to remain hidden. Portrait is the only supported orientation for this candidate.

This is a source-level layout guarantee. Dynamic Island/notch/Home Indicator behavior still requires the physical-device matrix in `docs/UI_LAYOUT.md`.

### Coach layer

`CameraService` delivers frames on a serial video-output queue. `CoachEngine` throttles analysis and runs Vision/luminance work on that queue, then publishes UI state on the main queue. This avoids manually retaining Core Video buffers and is compatible with current Swift/CoreVideo memory management.

Current signals:
- horizon;
- face/person rectangles;
- attention-based saliency;
- sampled luminance;
- approximate highlight/shadow clipping;
- rule-of-thirds proximity;
- basic person headroom.

The coach returns one prioritized recommendation rather than a numerical aesthetic score.

### UI and language

SwiftUI owns presentation. `ContentView` contains the direct language menu (System / English / Spanish), full-screen camera chrome, lens selector, coach output, format selector, and shutter controls.

`SettingsView` provides the same language choice plus composition-guide and coach-intensity preferences. `AppSettings` persists these private app settings with `UserDefaults`.

### Privacy boundary

No live frame is uploaded by the current source. Frames are processed in memory with Apple frameworks. Captured photo bytes are written to Photos only after user authorization.

`PrivacyInfo.xcprivacy` declares no tracking or collected-data types and declares the UserDefaults Required Reason API with CA92.1 for app-local settings.

### Build validation

GitHub Actions uses Xcode 26.x to compile the Release configuration without signing. CI validates both simulator and iPhoneOS SDK compilation. Signing, physical camera behavior, Archive validation, and App Store Connect processing remain separate release gates.

---

## Español

CapturePilot 0.2.0 separa cámara, análisis, interfaz, ajustes y distribución para que cada parte pueda evolucionar sin acoplar el resto.

### Capa de cámara

`CameraService` controla la sesión AVFoundation, entradas de cámara, salida fotográfica, frames para análisis, detección de capacidades, controles manuales, formatos y guardado en Fotos. Los cambios de sesión se realizan en una cola serial.

`CameraPreview` utiliza `AVCaptureVideoPreviewLayer` con `.resizeAspectFill`, convierte toques del visor a coordenadas de cámara, muestra la retícula de enfoque y usa la API moderna de ángulo de rotación de iOS 17+.

### Pantalla completa

El preview y las guías visuales llegan hasta los bordes físicos de la pantalla, incluso detrás de Dynamic Island/notch y Home Indicator. Los controles interactivos permanecen dentro de zonas seguras mediante safe-area padding.

La fila superior está separada del selector de lentes y éste puede desplazarse horizontalmente para evitar desbordamiento en pantallas pequeñas. La barra de estado se oculta durante la captura. Esta versión está diseñada deliberadamente para orientación vertical.

Esto se verificó en código y compilación; la geometría real de Dynamic Island/notch/Home Indicator todavía debe pasar la matriz física de `docs/UI_LAYOUT.md`.

### Coach

Los frames llegan por una cola serial de AVFoundation. `CoachEngine` limita la frecuencia de análisis, combina Vision con muestreo de luminancia y publica el resultado final en el hilo principal.

Actualmente analiza horizonte, rostro/persona, saliencia visual, luminancia, recorte aproximado de luces/sombras, proximidad a puntos de tercios y headroom básico.

El coach devuelve una recomendación prioritaria, no una puntuación estética.

### Interfaz e idioma

`ContentView` incluye un botón directo de idioma con **Sistema / English / Español**, además del selector equivalente en Ajustes. `AppSettings` persiste idioma, guía y nivel del coach mediante `UserDefaults`.

### Privacidad

El código actual no sube frames. El análisis ocurre localmente y una fotografía solo se agrega a Fotos después del permiso del usuario.

`PrivacyInfo.xcprivacy` declara que no hay tracking ni tipos de datos recopilados y declara UserDefaults con motivo CA92.1 para preferencias privadas de la propia app.

### Validación de build

GitHub Actions usa Xcode 26.x para compilar Release sin firma contra Simulator y SDK iPhoneOS. Firma, cámara física, Archive y procesamiento en App Store Connect siguen siendo puertas distintas antes de distribución.
