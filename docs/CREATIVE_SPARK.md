# Creative Spark / Chispa creativa

CapturePilot 0.9 adds **Creative Spark**, an optional, on-demand ideation layer for moments when the photographer wants another way to look at the scene.

Creative Spark is deliberately separate from the Coach.

- **Coach:** capture fundamentals and explainable photographic guidance.
- **Creative Spark:** optional exploration when the photographer asks for it.

It does not decide the composition and it never changes camera settings automatically.

---

## English

### Interaction

Creative Spark is triggered only by the **✦** HUD control.

1. Tap ✦.
2. CapturePilot analyzes the next live preview frame.
3. The analysis stops.
4. Up to four numbered creative anchors can appear on the viewfinder.
5. Up to three exploratory prompts appear beside the control.
6. The photographer can dismiss the result or request another scan.

The HUD control is optional and can be hidden through **Customize HUD**.

Changing scene mode, changing physical lens, or entering HUD-edit mode clears the current scan.

### Signals

A scan can use:

- Vision attention-based saliency objects;
- detected face/person as a strong subject anchor;
- the Coach's current vanishing point;
- the strongest current leading line;
- strong symmetry;
- a locally bright preview region that is above the frame average but below clipping;
- estimated negative space;
- an optional lower-frame foreground anchor for scene types where layering can be useful.

Creative Spark selects distinct anchors and caps the visible set at four.

It does **not** create fake detected points merely to fill the screen. If there is not enough evidence for multiple anchors, fewer or no numbered points can be shown.

### Prompt families

Current ideas include:

- make a detected point the visual anchor;
- move closer and simplify;
- exaggerate convergence;
- place the subject where a line leads;
- build around a pocket of light;
- intentionally preserve negative space;
- introduce a foreground layer;
- deliberately break strong symmetry;
- lower the camera;
- change camera height;
- isolate a macro/detail subject;
- build foreground / subject / background depth.

Scene mode influences which exploration is suggested, but no suggestion is mandatory.

### Preview geometry

Creative Spark stores the analyzed frame aspect ratio and maps normalized points through the same **aspect-fill geometry** used by the full-screen preview. This compensates for viewfinder crop instead of mapping points directly to screen coordinates.

Physical-device validation is still required for:
- every supported orientation;
- each physical lens;
- preview rotation;
- aspect-fill crop;
- Dynamic Island/notched layouts.

### Processing and privacy

Creative Spark runs locally.

No frame is uploaded and no result is sent to a CapturePilot cloud service.

Unlike the continuously available live Coach, the Creative Spark Vision request is only started after explicit user action.

### What it is not

Creative Spark does not claim to understand:
- artistic intent;
- narrative meaning;
- emotion;
- taste;
- whether an unusual composition should be changed;
- the objectively "best" point in a scene.

The markers are **possible creative anchors**, not a correctness map.

### Acceptance gates

- points line up with real preview objects after aspect-fill;
- markers remain correct in portrait, landscape left/right, and upside-down portrait;
- changing lens clears stale points;
- changing scene clears stale points;
- HUD editing clears the scan;
- no automatic exposure/focus/lens/LUT/crop changes;
- no invented marker when no signal exists;
- scan does not noticeably interrupt preview/capture;
- prompts remain useful across General, Portrait, Architecture, Automotive, Macro, Street, Landscape, and Night.

---

## Español

CapturePilot 0.9 agrega **Chispa creativa**, una capa opcional y bajo demanda para momentos de bloqueo creativo.

Está separada del Coach:

- **Coach:** fundamentos de captura y guía fotográfica explicable.
- **Chispa creativa:** exploración opcional sólo cuando el fotógrafo la solicita.

Nunca cambia parámetros automáticamente ni decide la composición.

### Interacción

1. Toca **✦**.
2. CapturePilot analiza el siguiente frame del preview.
3. El análisis se detiene.
4. Pueden aparecer hasta cuatro anchors creativos numerados.
5. Se muestran hasta tres propuestas de exploración.
6. Puedes cerrar el resultado o escanear de nuevo.

El control puede ocultarse desde **Personalizar HUD**.

Cambiar de escena, lente física o entrar en edición del HUD elimina el scan actual.

### Señales

Puede usar:

- objetos de saliencia de Vision;
- rostro/persona;
- punto de fuga actual;
- línea guía dominante;
- simetría fuerte;
- una región de luz local por encima del promedio sin estar recortada;
- espacio negativo estimado;
- anchor de primer plano en escenas donde una capa cercana puede ser útil.

No inventa marcadores para rellenar la pantalla. Si no existe suficiente evidencia, puede mostrar pocos o ningún punto y aun así proponer una exploración general.

### Ideas actuales

- convertir un punto en ancla;
- acercarse y simplificar;
- exagerar convergencia;
- aprovechar una línea;
- construir alrededor de una zona de luz;
- preservar espacio negativo;
- añadir una capa de primer plano;
- romper simetría deliberadamente;
- bajar la cámara;
- cambiar altura;
- aislar un detalle;
- crear capas de profundidad.

### Geometría del visor

El resultado conserva la relación de aspecto del frame y transforma los puntos con geometría **aspect-fill**, compensando el crop del visor full-screen.

La alineación real todavía debe validarse por orientación y lente.

### Privacidad

Todo el análisis ocurre en el dispositivo y sólo se ejecuta después de tocar ✦.

No se suben frames ni resultados.

### Qué no pretende hacer

No afirma conocer:
- intención artística;
- historia;
- emoción;
- gusto;
- si una composición extraña debe corregirse;
- el punto objetivamente "mejor".

Los puntos son **posibles anchors creativos**, no un mapa de corrección.
