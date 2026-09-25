# CapturePilot Coach / Coach de CapturePilot

CapturePilot's Coach is a **deterministic, on-device photography guidance system**. It does not generate an aesthetic score, does not upload frames, and does not replace the photographer's creative decision.

El Coach de CapturePilot es un **sistema determinista de guía fotográfica que funciona en el dispositivo**. No genera una puntuación estética, no sube frames y no sustituye la decisión creativa del fotógrafo.

---

## English

### 1. Signal source and cadence

The Coach receives the same `CMSampleBuffer` stream produced by the camera's `AVCaptureVideoDataOutput`.

`CoachEngine`:
- processes at most one analysis approximately every **0.28 s** (~3.6 analyses/s maximum);
- refuses to start another analysis while one is already running;
- performs all current analysis locally.

This rate is intentionally lower than the camera preview frame rate. The Coach is meant to give stable photographic guidance, not react to every individual video frame.

### 2. Perception layer

Each analyzed frame can contribute several independent signals.

#### Apple Vision

The current implementation uses:
- `VNDetectFaceRectanglesRequest`;
- `VNDetectHumanRectanglesRequest`;
- `VNDetectHorizonRequest`;
- `VNGenerateAttentionBasedSaliencyImageRequest`.

Priority for subject localization is:
1. detected face;
2. detected human;
3. strongest attention-based salient object;
4. no subject if none of those signals is available.

The resulting subject/saliency position is used for composition guidance.

#### Luminance

The luma plane is sampled on a sparse grid.

The Coach derives:
- average luma;
- approximate highlight clipping ratio;
- approximate shadow clipping ratio.

Current preview-luma sample thresholds:
- highlight sample: luma >= **248/255**;
- shadow sample: luma <= **14/255**.

These are preview-derived heuristics, not RAW sensor clipping measurements.

#### Geometry and detail

For geometric analysis the luma image is reduced to a **64 × 48** grid.

The current analyzer derives:
- vertical symmetry;
- local edge/detail energy;
- strong line candidates using a compact Hough-style accumulator;
- leading-line score;
- possible vanishing point;
- negative-space estimate.

Current Hough-style configuration:
- 36 angle bins;
- 64 rho bins;
- local edge threshold: magnitude > **0.12**;
- up to 5 strong line candidates are retained;
- up to 4 lines can be exposed to the Teaching overlay.

These values are intentionally heuristic.

### 3. Composition-point classification

The strongest subject/saliency position is compared with several compositional strong points.

#### Rule of thirds

Four intersections at 1/3 and 2/3.

Current “near” radius: **0.115** in normalized image coordinates.

#### Golden points

Four points around 0.382 / 0.618.

Current “near” radius: **0.105**.

These points currently drive the Macro/golden-spiral guidance.

#### Golden-triangle guidance points

Four approximate strong points at 0.25 / 0.75.

Current “near” radius: **0.13**.

These points currently influence Landscape guidance.

### 4. Decision priority

The Coach does not average every metric into a single score. It follows a priority tree.

Before scene-specific composition guidance, the current order is:

1. horizon;
2. excessive highlights / very bright frame;
3. excessive shadows / very dark frame, except for the Night-specific rule;
4. Night-specific exposure/detail behavior;
5. scene-specific composition guidance.

This means a badly tilted or severely overexposed frame can override a composition suggestion. CapturePilot intentionally prioritizes fixing a fundamental capture problem before suggesting a more subjective compositional refinement.

### 5. Horizon thresholds

Architecture and Landscape use stricter leveling thresholds.

| Scene group | Subtle | Balanced / Teaching |
| --- | ---: | ---: |
| Architecture / Landscape | 2.2° | 1.2° |
| Other modes | 3.5° | 2.0° |

### 6. Exposure rules

Current high-priority caution rules include:

- highlight clip ratio > **0.07**, or average luma > **0.82** → lower exposure;
- outside Night: shadow clip ratio > **0.32**, or average luma < **0.16** → scene considered too dark;
- Night: average luma < **0.07** → too dark;
- Night: detail score < **0.12** → stabilize camera and protect highlights.

These thresholds are product heuristics and remain subject to physical-device validation.

### 7. Coach intensity

#### Subtle

Subtle still warns about high-priority capture problems such as:
- horizon;
- highlight clipping / excessive brightness;
- excessive darkness;
- Night-specific low-light/stability conditions.

Once those checks pass, Subtle returns to **Ready** rather than giving continuous compositional instructions.

#### Balanced

Balanced adds scene-specific compositional guidance.

#### Teaching

Teaching uses the same current recommendation logic as Balanced, but reveals more explanation:
- secondary Coach message;
- detected leading-line overlay;
- usable vanishing-point marker;
- additional technical metrics such as symmetry and line score.

Teaching therefore exposes more of the Coach's reasoning; it is not currently a separate ML model or a more aggressive decision engine.

### 8. Scene modes

The photographer selects the scene mode explicitly. CapturePilot does not currently claim automatic scene classification.

#### General

Priority:
1. strong symmetry;
2. strong leading-line geometry;
3. subject placement / thirds.

Current examples:
- symmetry score > **0.90** → “Symmetry is well defined”;
- leading-line score > **0.42** → use leading lines.

#### Portrait

Priority:
1. person/headroom;
2. subject placement.

If a detected person's bounding box ends below the current headroom threshold (`subject.maxY < 0.76`), the Coach suggests reducing headroom.

#### Architecture

Priority:
1. strict horizon;
2. symmetry;
3. vanishing geometry;
4. leading lines.

Current strong-symmetry threshold: **0.86**.

#### Automotive

Priority:
1. leading lines;
2. negative space;
3. subject placement.

Current line threshold: **0.35**.
Current negative-space threshold: **0.60**.

#### Macro

Priority:
1. detail;
2. golden-point placement.

Current low-detail threshold: **0.14**.

If detail is low, the Coach suggests refining focus and stabilizing. If detail is sufficient and the subject is near a golden point, it reports positive balance.

#### Street

Priority:
1. leading lines;
2. negative space;
3. subject placement.

Current line threshold: **0.32**.
Current negative-space threshold: **0.58**.

#### Landscape

Priority:
1. strict horizon;
2. golden-triangle placement;
3. leading lines;
4. negative space;
5. subject placement.

Current leading-line thresholds are approximately **0.30–0.34** depending on the branch of the decision tree.

#### Night

Night deliberately avoids treating ordinary darkness as automatically wrong.

Priority:
1. extremely low exposure;
2. low-detail stability warning;
3. leading lines when present;
4. stabilization + highlight protection.

### 9. Subject-placement guidance

When a scene reaches generic subject-placement logic:

- no subject → Ready;
- subject near a thirds intersection → positive “Subject is near a strong point”;
- otherwise the Coach finds the nearest thirds intersection and suggests moving the framing left/right/up/down.

The Coach moves the **framing**, not the subject. The photographer remains responsible for deciding whether the suggestion is appropriate.

### 10. Message stabilization

To reduce flicker, a new primary message must be selected for **two consecutive analyzed frames** before it becomes the published recommendation.

At the nominal 0.28 s analysis interval, the earliest stable change is roughly 0.56 s, but actual timing can be longer depending on frame availability and processing.

While a new message is waiting for confirmation, the previously published primary message remains visible and the new secondary message is suppressed.

### 11. UI representation

`CoachState` publishes:
- primary message;
- optional secondary message;
- severity: neutral / positive / caution;
- horizon;
- saliency/subject geometry;
- luminance/clipping estimates;
- detail;
- thirds/golden classifications;
- symmetry;
- leading-line score;
- negative space;
- vanishing point;
- detected lines.

`CoachBubble` shows:
- primary recommendation in all modes;
- secondary recommendation only in Teaching;
- an icon corresponding to neutral / positive / caution.

### 12. What the Coach is not

The current Coach is **not**:
- an aesthetic-quality score;
- a generative AI critic;
- an automatic scene classifier;
- a guarantee that a composition is “correct”;
- RAW/sensor exposure analysis;
- a replacement for photographer intent.

Its job is to surface explainable signals and make one practical suggestion at a time.

### 13. Known validation gates

Before describing the Coach as physically validated, CapturePilot still needs:
- real-scene testing across all eight scene modes;
- orientation/lens alignment checks for Vision and geometry;
- controlled horizon/exposure tests;
- false-positive testing for lines/vanishing points;
- thermal/performance testing with scopes + Coach active;
- deterministic tests for the rule-selection logic.

---

## Español

### 1. Fuente y frecuencia de análisis

El Coach recibe el mismo `CMSampleBuffer` generado por `AVCaptureVideoDataOutput`.

`CoachEngine`:
- procesa como máximo un análisis aproximadamente cada **0.28 s** (~3.6 análisis/s);
- no inicia otro análisis mientras uno sigue ejecutándose;
- mantiene todo el análisis actual dentro del dispositivo.

No intenta reaccionar a cada frame del preview: prioriza una guía fotográfica estable.

### 2. Capa de percepción

#### Apple Vision

Se utilizan:
- `VNDetectFaceRectanglesRequest`;
- `VNDetectHumanRectanglesRequest`;
- `VNDetectHorizonRequest`;
- `VNGenerateAttentionBasedSaliencyImageRequest`.

Prioridad para localizar sujeto:
1. rostro;
2. persona;
3. objeto con mayor saliencia visual;
4. sin sujeto cuando ninguna señal está disponible.

#### Luminancia

Se muestrea el plano Y en una cuadrícula dispersa.

Se calculan:
- luminancia promedio;
- clipping aproximado de luces;
- clipping aproximado de sombras.

Umbrales actuales del preview:
- luz recortada: luma >= **248/255**;
- sombra recortada: luma <= **14/255**.

No son mediciones RAW del sensor.

#### Geometría y detalle

La imagen de luminancia se reduce a una cuadrícula **64 × 48**.

Se estiman:
- simetría vertical;
- energía de bordes/detalle;
- líneas fuertes mediante un acumulador compacto tipo Hough;
- fuerza de líneas guía;
- posible punto de fuga;
- espacio negativo.

Configuración actual:
- 36 bins angulares;
- 64 bins rho;
- umbral local de borde > **0.12**;
- hasta 5 candidatos de línea;
- hasta 4 líneas visibles en modo Didáctico.

Son heurísticas, no mediciones infalibles.

### 3. Clasificación de puntos compositivos

#### Tercios

Intersecciones de 1/3 y 2/3.

Radio actual: **0.115**.

#### Puntos áureos

Puntos 0.382 / 0.618.

Radio actual: **0.105**.

Actualmente alimentan la guía de Macro/espiral áurea.

#### Puntos de triángulo áureo

Puntos aproximados 0.25 / 0.75.

Radio actual: **0.13**.

Influyen en Paisaje.

### 4. Prioridad de decisiones

El Coach **no** convierte todo en una puntuación.

La jerarquía actual es:

1. horizonte;
2. luces excesivas / sobreexposición;
3. sombras excesivas / escena demasiado oscura, salvo reglas específicas de Noche;
4. comportamiento especial de Noche;
5. guía compositiva específica de escena.

Un problema fundamental de captura tiene prioridad sobre una sugerencia estética.

### 5. Umbral de horizonte

| Grupo | Sutil | Equilibrado / Didáctico |
| --- | ---: | ---: |
| Arquitectura / Paisaje | 2.2° | 1.2° |
| Otros modos | 3.5° | 2.0° |

### 6. Reglas de exposición

Reglas actuales:

- clipping de luces > **0.07**, o luminancia promedio > **0.82** → bajar exposición;
- fuera de Noche: clipping de sombras > **0.32**, o luminancia promedio < **0.16** → demasiado oscuro;
- Noche: luminancia promedio < **0.07** → demasiado oscuro;
- Noche: detalle < **0.12** → estabilizar y proteger luces.

Son heurísticas de producto pendientes de validación física.

### 7. Intensidad

#### Sutil

Sólo insiste en problemas prioritarios de captura. Si esos problemas no existen, vuelve a **Listo** en vez de dar instrucciones compositivas continuas.

#### Equilibrado

Agrega recomendaciones compositivas específicas de escena.

#### Didáctico

Actualmente comparte la misma selección principal que Equilibrado, pero expone más razonamiento:
- mensaje secundario;
- líneas detectadas;
- punto de fuga;
- métricas extra como simetría y fuerza de líneas.

No es un modelo de IA diferente.

### 8. Modos de escena

El fotógrafo elige el modo; no se anuncia clasificación automática.

#### General
Simetría fuerte → líneas guía → colocación del sujeto.

Umbrales principales:
- simetría > **0.90**;
- líneas > **0.42**.

#### Retrato
Headroom/persona → colocación.

Umbral actual de headroom: `subject.maxY < 0.76`.

#### Arquitectura
Horizonte estricto → simetría → punto de fuga → líneas.

Simetría fuerte > **0.86**.

#### Automotriz
Líneas → espacio negativo → sujeto.

- líneas > **0.35**;
- espacio negativo > **0.60**.

#### Macro
Detalle → puntos áureos.

Detalle bajo < **0.14**.

#### Calle
Líneas → espacio negativo → sujeto.

- líneas > **0.32**;
- espacio negativo > **0.58**.

#### Paisaje
Horizonte estricto → triángulo áureo → líneas → espacio negativo → sujeto.

Líneas alrededor de **0.30–0.34** según la rama de decisión.

#### Noche
No penaliza automáticamente una escena sólo por ser oscura.

Prioriza exposición extremadamente baja, estabilidad, protección de luces y líneas cuando existen.

### 9. Colocación del sujeto

Cuando se usa la lógica genérica:

- sin sujeto → Listo;
- cerca de tercios → mensaje positivo;
- fuera de tercios → se busca la intersección de tercios más cercana y se propone mover el encuadre izquierda/derecha/arriba/abajo.

Es una sugerencia, no una orden creativa.

### 10. Estabilización de mensajes

Una recomendación nueva debe aparecer en **dos análisis consecutivos** antes de publicarse.

Con intervalo nominal de 0.28 s, el cambio estable más rápido ronda 0.56 s, aunque puede tardar más.

Mientras se confirma, permanece el mensaje anterior.

### 11. Estado y UI

`CoachState` mantiene mensajes, severidad y las métricas calculadas.

`CoachBubble`:
- muestra siempre el mensaje principal;
- muestra el secundario sólo en Didáctico;
- cambia el icono entre neutral, positivo y precaución.

### 12. Qué no es

El Coach actual **no es**:
- un score estético;
- un crítico generativo;
- un clasificador automático de escenas;
- garantía de composición “correcta”;
- análisis RAW/sensor;
- sustituto de la intención del fotógrafo.

Su función es mostrar señales explicables y una recomendación práctica a la vez.

### 13. Validaciones pendientes

Antes de considerarlo validado físicamente faltan:
- pruebas reales de los ocho modos;
- alineación Vision/geometría por lente y orientación;
- pruebas controladas de horizonte/exposición;
- falsos positivos de líneas/puntos de fuga;
- carga térmica con scopes + Coach;
- tests deterministas para la lógica de selección.
