# Professional Monitoring / Monitoreo profesional

CapturePilot's monitoring tools are designed for **still photography**. They help the photographer judge exposure, tonal distribution, color balance, clipping, and focus before making a photograph.

They do not add video-recording parameters, codecs, bitrate controls, audio meters, or other video-production workflows.

## English

### Signal source

Histogram, False Color, Waveform, RGB Parade, Vectorscope, and Zebras are derived from the live **YCbCr preview stream** supplied by AVFoundation.

That means they are useful operational monitoring tools, but they are **not**:
- sensor-linear measurements;
- RAW-file histograms;
- calibrated IRE instrumentation;
- substitutes for inspecting the captured RAW/ProRAW file.

This distinction is intentional and documented in the UI.

### Zebra

CapturePilot supports two exposure-warning thresholds:
- low Zebra: 50–95%;
- high Zebra: 75–100%;
- dual Zebra can be disabled for a single high-level warning.

The low and high bands use different stripe/color treatments so they can be distinguished at a glance.

### False Color

False Color maps preview luminance into exposure zones. It is intended to make relative exposure relationships easier to see than a normal preview.

The palette is **preview-relative** and is not described as a calibrated sensor/IRE scale.

### Histogram

The RGB histogram contains 256 bins per channel and derives approximate RGB values from the preview YCbCr planes.

It also reports per-channel shadow/highlight clipping indicators.

### Luma Waveform

The waveform preserves horizontal image position and plots preview luminance vertically from dark to bright.

Use it to judge:
- highlight placement;
- shadow placement;
- left-to-right exposure differences;
- gradients that a global histogram can hide.

### RGB Parade

RGB Parade displays red, green, and blue level distributions separately while retaining horizontal image position.

It is useful for spotting:
- color-channel clipping;
- strong color casts;
- imbalance between channels.

### Vectorscope

The vectorscope plots preview chroma around a neutral center.

It is useful for:
- judging saturation;
- identifying dominant color direction;
- checking whether a scene is drifting strongly toward a hue.

It is not a colorimeter.

### Focus Peaking

Focus Peaking uses local luminance gradients as a micro-contrast focus aid.

The photographer can configure:
- edge threshold;
- overlay color.

A lower threshold marks more edges. A higher threshold requires stronger micro-contrast.

### AF/AE Lock

- tap on the preview: focus + meter;
- long press: resolve focus/exposure at the selected point, then lock AF and AE;
- tapping again or switching to manual exposure/focus returns control to the appropriate automatic/manual state;
- an optional HUD button can lock/unlock without relying on the gesture.

### Frame guides

Frame guides preview crop ratios without changing capture resolution:
- 1:1
- 4:3
- 3:2
- 16:9
- 2.39:1

### Performance design

All monitoring tools share the existing video-data stream. No extra camera session or extra capture output is created for each scope.

Each expensive tool is throttled independently and processing is disabled when its corresponding HUD tool is not active/visible where practical.

---

## Español

Las herramientas de monitoreo de CapturePilot están diseñadas para **fotografía fija**. Ayudan a evaluar exposición, distribución tonal, color, clipping y enfoque antes de tomar la fotografía.

No agregan parámetros de grabación de video, codecs, bitrate, medidores de audio ni flujos propios de producción de video.

### Fuente de señal

Histograma, False Color, Waveform, RGB Parade, Vectorscope y Cebras se derivan del **preview YCbCr** entregado por AVFoundation.

Por lo tanto son ayudas útiles de monitoreo, pero **no** son:
- mediciones lineales del sensor;
- histogramas del archivo RAW;
- instrumentos IRE calibrados;
- sustitutos de inspeccionar el RAW/ProRAW capturado.

### Cebras

CapturePilot soporta:
- cebra baja: 50–95%;
- cebra alta: 75–100%;
- modo dual opcional.

Las dos bandas se distinguen mediante tratamiento visual diferente.

### False Color

False Color convierte la luminancia del preview en zonas de color para visualizar relaciones de exposición.

La escala es relativa al preview y no se presenta como medición IRE calibrada.

### Histograma

El histograma RGB usa 256 bins por canal y deriva valores RGB aproximados desde YCbCr.

También genera avisos de clipping por canal en sombras y luces.

### Waveform Luma

Mantiene la posición horizontal de la imagen y representa luminancia de oscuro a claro.

Ayuda a detectar diferencias de exposición que un histograma global puede ocultar.

### RGB Parade

Separa rojo, verde y azul manteniendo la posición horizontal aproximada.

Ayuda a identificar clipping por canal y dominantes de color.

### Vectorscope

Representa crominancia alrededor de un centro neutro.

Sirve para evaluar saturación y dirección dominante de color, pero no es un colorímetro.

### Focus Peaking

Usa gradientes locales de luminancia como ayuda de microcontraste.

Se puede configurar:
- umbral;
- color.

### AF/AE Lock

- toque: enfoque + medición;
- pulsación larga: resuelve el punto seleccionado y después bloquea AF/AE;
- un toque posterior o pasar a controles manuales libera el estado correspondiente;
- existe además un botón HUD opcional.

### Guías de formato

Previsualizan proporciones sin cambiar la resolución capturada:
- 1:1
- 4:3
- 3:2
- 16:9
- 2.39:1

### Rendimiento

Todas las herramientas reutilizan el mismo stream de video-data. No se crea una sesión ni un output adicional por scope.

El trabajo costoso está limitado por frecuencia y se detiene cuando la herramienta correspondiente no se necesita, siempre que el flujo lo permita.
