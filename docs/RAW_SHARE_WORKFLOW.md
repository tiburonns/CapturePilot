# RAW + Share JPEG Workflow / Flujo RAW + JPEG para compartir

CapturePilot 0.6 adds a still-photography workflow designed for photographers who want a high-quality RAW working file and a ready-to-share JPEG from the same shutter press.

## English

### Goal

One shutter press should produce:

1. an untouched RAW or Apple ProRAW working file at the maximum photo dimensions requested from the active camera format; and
2. a processed JPEG derived from the **same AVFoundation capture request**, optionally transformed with a user-imported 3D LUT and downsampled to a sharing resolution.

The workflow does not perform two sequential shutter events.

### Capture path

```text
Shutter
  ↓
AVCapturePhotoSettings
RAW/ProRAW + processed JPEG
maxPhotoDimensions = active-format maximum
  ↓
AVCapturePhotoOutput
  ├─ RAW result ───────────────────────────────┐
  └─ processed companion                      │
            ↓                                 │
       Core Image                             │
       optional .cube LUT                     │
       LUT intensity                          │
       Lanczos downsample                     │
       JPEG sRGB                              │
            ↓                                 │
       Share JPEG                             │
            └──────────────┬──────────────────┘
                           ↓
                     Photos asset
               JPEG primary + RAW alternate
                 (fallback: two assets)
```

### Capability policy

CapturePilot exposes the RAW + Share workflow only when the active configuration currently has:
- a Bayer RAW or Apple ProRAW pixel format;
- JPEG processed capture support;
- an active-format maximum resolution in the approximate 48 MP class (currently >= 40 MP).

When Apple ProRAW is available, the workflow prefers it. Otherwise it uses a Bayer RAW format.

This is capability-driven. CapturePilot does not synthesize a 48 MP RAW mode.

### Resolution

The RAW+processed AVFoundation request uses the active format's maximum valid `maxPhotoDimensions`.

The Share JPEG target can be:
- 12 MP;
- 24 MP;
- 48 MP.

The post-processing pipeline **never upscales**. If the processed companion contains fewer pixels than the chosen target, CapturePilot keeps the source dimensions.

The resulting target is therefore an approximate megapixel target preserving the captured aspect ratio.

### LUT pipeline

The current importer supports 3D IRIDAS-style `.cube` LUTs:
- `LUT_3D_SIZE` from 2 to 65;
- standard 0–1 input domain;
- red-fastest cube ordering;
- optional `TITLE`;
- optional `DOMAIN_MIN` / `DOMAIN_MAX` or `LUT_3D_INPUT_RANGE`.

The LUT is copied into CapturePilot's Application Support directory. Processing remains on-device.

Core Image applies the cube in sRGB output space. LUT intensity is adjustable from 0–100%.

Current scope intentionally rejects:
- 1D-only LUTs;
- non-0–1 input domains;
- malformed or incomplete cube tables.

### JPEG output

The Share JPEG:
- comes from the processed companion of the RAW capture;
- applies orientation metadata when decoding;
- optionally applies the LUT;
- uses Lanczos downsampling;
- exports as sRGB JPEG;
- uses JPEG quality 0.94;
- is written to a temporary local URL for the iOS Share Sheet.

JPEG and JPG refer to the same image format; CapturePilot uses a `.jpg` filename for the share copy.

### Photos pairing

CapturePilot first attempts to create one Photos asset using:
- JPEG as `.photo`;
- RAW as `.alternatePhoto`.

If Photos rejects the resource combination, CapturePilot falls back to two separate assets so the capture is not discarded.

### What remains to validate physically

Before claiming Fotorgear-equivalent behavior on a specific iPhone/lens:
- verify RAW/ProRAW output pixel dimensions;
- verify processed companion dimensions;
- verify 12/24/48 MP JPEG output dimensions;
- verify RAW + JPEG pairing in Photos;
- verify LUT color against known reference images;
- test 17/33/65-point LUTs;
- validate memory/processing time for 48 MP JPEG + 65³ LUT;
- verify metadata/orientation after processing;
- test every physical lens that exposes the workflow.

---

## Español

CapturePilot 0.6 agrega un flujo para obtener un archivo RAW de trabajo y un JPEG listo para compartir desde **el mismo disparo**.

### Objetivo

Un toque al disparador produce:

1. RAW o Apple ProRAW sin LUT ni redimensionado, solicitando la máxima dimensión válida del formato activo;
2. JPEG procesado del mismo request AVFoundation, con LUT opcional y resolución de salida elegida.

No se realizan dos disparos consecutivos.

### Política de capabilities

El modo RAW + JPEG sólo aparece como utilizable cuando la configuración activa tiene:
- Bayer RAW o Apple ProRAW;
- JPEG processed;
- resolución máxima de clase aproximada 48 MP (actualmente >= 40 MP).

Se prefiere ProRAW cuando está disponible; Bayer RAW es el fallback.

CapturePilot no inventa 48 MP.

### Resolución JPEG

Objetivos:
- 12 MP;
- 24 MP;
- 48 MP.

Nunca se hace upscale. El pipeline conserva relación de aspecto y reduce con Lanczos.

### LUT

Se pueden importar LUT 3D `.cube` desde Files.

Soporte actual:
- tamaños 2–65;
- dominio de entrada 0–1;
- orden IRIDAS red-fastest;
- intensidad 0–100%.

El LUT se copia a Application Support y se procesa localmente mediante Core Image.

No se aceptan todavía LUT 1D, dominios no estándar ni cubos incompletos.

### Guardado y compartir

El JPEG final:
- se exporta sRGB;
- usa calidad JPEG 0.94;
- queda disponible temporalmente para Share Sheet;
- se guarda junto al RAW cuando Photos acepta JPEG principal + RAW alternativo.

Si Photos rechaza el pairing, ambos archivos se guardan como assets separados.

### Validación pendiente

Antes de afirmar equivalencia física con el flujo de Fotorgear faltan pruebas reales de:
- dimensiones RAW/ProRAW;
- processed companion;
- JPEG 12/24/48;
- pairing de Fotos;
- precisión de LUT;
- rendimiento/memoria;
- metadata/orientación;
- comportamiento por lente.
