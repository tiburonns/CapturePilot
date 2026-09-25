# CapturePilot

**Professional photography, guided — not automated.**

CapturePilot is a free, ad-free iOS camera that combines professional manual controls with an on-device photography coach. The goal is not to make creative decisions for the photographer. It analyzes technical and compositional signals, then surfaces one useful suggestion at a time while keeping the photographer in control.

> Current status: **0.1 — first device-test baseline**

## English

### Philosophy

- **Photographer first.** The coach suggests; it never decides what a "good" photo must look like.
- **Real controls only.** A visible control must be connected to working behavior. Experimental features stay out of the UI until implemented.
- **Private by design.** Live analysis uses Apple frameworks on-device. No account, ads, analytics SDKs, or trackers are required.
- **Learn while shooting.** Subtle, Balanced, and Teaching coach modes progressively change how much guidance is shown.
- **Native iOS.** SwiftUI + AVFoundation + Vision, with no third-party runtime dependencies in the current baseline.

### Implemented in 0.1

#### Camera
- Live AVFoundation viewfinder
- Rear-camera discovery: Ultra Wide, Wide, and Telephoto when present
- HEIF and JPEG capture
- RAW/DNG capture when the active configuration supports it
- Save to Photos with add-only permission
- Tap-to-focus and tap-to-meter
- Capture-quality prioritization

#### Pro controls
- Exposure compensation (EV)
- Auto/manual exposure
- ISO control
- Shutter-duration control
- Auto/manual focus
- Manual lens position
- Auto/manual white balance
- Color-temperature control

#### Composition coach
- Horizon detection
- Face/person detection
- Attention-based saliency detection
- Approximate highlight/shadow clipping analysis from luma samples
- Rule-of-thirds strong-point guidance
- Headroom warning for people
- Message stabilization to reduce rapid suggestion flicker
- Three coach levels: Subtle, Balanced, Teaching

#### Composition guides
- Rule of thirds
- Golden-ratio grid
- Crosshair
- Level indicator

#### Product quality
- English / Spanish / System language selector
- Persistent user preferences
- Localized camera and Photo Library permission strings
- Privacy Manifest (`PrivacyInfo.xcprivacy`)
- No ads, accounts, analytics SDKs, trackers, or external service dependency

### Intentionally not exposed yet

The following features are planned, but **are not presented as working controls in 0.1**:

- Focus peaking
- Zebra overlays
- RGB/luminance histogram
- Apple ProRAW workflow
- Advanced scene-specific coaches (portrait, architecture, automotive, macro, street, landscape, night)
- Leading-line / symmetry / vanishing-point analysis
- Golden spiral / golden triangle overlays
- Post-capture teaching review
- Bracketing and advanced computational capture workflows

See [ROADMAP.md](docs/ROADMAP.md).

### Build

1. Clone the repository.
2. Open `CapturePilot.xcodeproj` in Xcode.
3. Select the `CapturePilot` target.
4. Choose your signing team.
5. If needed, change `com.tiburonns.CapturePilot` to a bundle identifier available to your Apple account.
6. Build on a physical iPhone running iOS 17 or later.

A physical device is required for meaningful camera/RAW testing. Simulator validation is not a substitute for the first camera test.

### First real-device test

Use [TESTING.md](docs/TESTING.md). The most important first-pass checks are camera startup, every available lens, tap-to-focus, HEIF/JPEG capture, RAW availability, manual exposure/focus/WB, and coach behavior under level/bright/dark/person scenes.

### Architecture

See [ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Español

### Filosofía

- **Primero el fotógrafo.** El coach sugiere; nunca decide qué debe considerarse una fotografía "buena".
- **Solo controles reales.** Todo control visible debe estar conectado a una función real. Las funciones experimentales no aparecen hasta estar implementadas.
- **Privacidad desde el diseño.** El análisis en vivo usa frameworks de Apple en el dispositivo. No se requiere cuenta, anuncios, SDK de analítica ni rastreadores.
- **Aprender mientras fotografías.** Los modos Sutil, Equilibrado y Didáctico cambian progresivamente la cantidad de guía mostrada.
- **iOS nativo.** SwiftUI + AVFoundation + Vision, sin dependencias externas de ejecución en esta base.

### Implementado en 0.1

#### Cámara
- Visor en vivo con AVFoundation
- Detección de cámara Ultra Wide, Wide y Telephoto cuando estén disponibles
- Captura HEIF y JPEG
- Captura RAW/DNG cuando la configuración activa lo soporte
- Guardado en Fotos con permiso de solo agregar
- Tocar para enfocar y medir exposición
- Priorización de calidad de captura

#### Controles Pro
- Compensación de exposición (EV)
- Exposición automática/manual
- Control ISO
- Control de tiempo de obturación
- Enfoque automático/manual
- Posición manual de lente
- Balance de blancos automático/manual
- Control de temperatura de color

#### Coach de composición
- Detección de horizonte
- Detección de rostro/persona
- Detección de saliencia visual
- Análisis aproximado de recorte de altas luces/sombras mediante luminancia
- Guía hacia puntos fuertes de regla de tercios
- Aviso de espacio excesivo sobre personas
- Estabilización del mensaje para evitar recomendaciones que parpadeen rápidamente
- Tres niveles: Sutil, Equilibrado y Didáctico

#### Guías
- Regla de tercios
- Cuadrícula de proporción áurea
- Cruz central
- Indicador de nivel

#### Calidad del producto
- Selector Inglés / Español / Sistema
- Preferencias persistentes
- Textos de permisos de cámara y fototeca localizados
- Privacy Manifest (`PrivacyInfo.xcprivacy`)
- Sin anuncios, cuentas, SDK de analítica, rastreadores ni dependencia de un servicio externo

### Aún no expuesto como función

Estas funciones están planeadas, pero **no se muestran como controles funcionales en 0.1**:

- Focus peaking
- Cebras
- Histograma RGB/luminancia
- Flujo Apple ProRAW
- Coaches avanzados por escena (retrato, arquitectura, automotriz, macro, calle, paisaje, noche)
- Detección de líneas guía, simetría y punto de fuga
- Espiral y triángulo áureo
- Revisión didáctica después de capturar
- Bracketing y captura computacional avanzada

Consulta [ROADMAP.md](docs/ROADMAP.md).

### Compilar

1. Clona el repositorio.
2. Abre `CapturePilot.xcodeproj` en Xcode.
3. Selecciona el target `CapturePilot`.
4. Elige tu equipo de firma.
5. Si es necesario, cambia `com.tiburonns.CapturePilot` por un Bundle ID disponible en tu cuenta de Apple.
6. Compila en un iPhone físico con iOS 17 o posterior.

Para validar cámara y RAW se requiere un dispositivo físico. El simulador no sustituye la primera prueba real.

### Primera prueba real

Sigue [TESTING.md](docs/TESTING.md). Las verificaciones prioritarias son inicio de cámara, todas las lentes disponibles, tap-to-focus, captura HEIF/JPEG, disponibilidad RAW, exposición/enfoque/WB manual y comportamiento del coach con horizonte, escenas claras/oscuras y personas.

### Arquitectura

Consulta [ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Technology

- Swift
- SwiftUI
- AVFoundation
- Vision
- Photos

## Inspiration

CapturePilot studies successful ideas from modern professional and guided-camera workflows, but uses its own architecture, interface, naming, logic, and implementation. It is not intended to reproduce proprietary code, assets, or UI from another product.
