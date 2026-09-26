# Photo Rankings + Coach Review / Ranking de fotos + revisión del Coach

CapturePilot 0.8 adds a private post-shot review and ranking system for still photography.

The goal is not to declare artistic truth. The goal is to help a photographer compare their own images consistently, find stronger frames quickly, filter by photographic category, and receive actionable ideas for a second attempt.

---

## English

### What enters Rankings

CapturePilot can analyze:

1. **new CapturePilot captures** automatically; and
2. **user-selected imported images** through the system Photos picker.

Imported originals are used for analysis but are not copied into CapturePilot's ranking storage. CapturePilot stores:
- a small JPEG thumbnail;
- analysis metrics;
- category;
- tags;
- recommendations;
- date/source metadata;
- a SHA-256 fingerprint used to avoid duplicate entries.

### Rankings UI

The Rankings section supports:

- Top 5;
- Top 10;
- Top 25;
- Top 50;
- All categories or one selected category;
- Photo detail/review;
- Delete from CapturePilot Rankings without deleting the original from Photos.

Current categories:

- General
- Portrait
- Architecture
- Automotive
- Macro
- Street
- Landscape
- Night

### Automatic category classification

Post-shot category inference is independent from the live scene selector whenever CapturePilot has stronger evidence.

Current order:

1. face detected → Portrait;
2. very low average luminance → Night;
3. Vision image classifications are checked for automotive, architecture, landscape, macro and street cues;
4. if classification is inconclusive, the selected live Coach scene can act as a fallback;
5. otherwise → General.

This is heuristic classification, not a claim that every image has one objectively correct genre.

### Coach Score

Each photo receives a **Coach Score from 0–100**.

The score is intentionally presented as a **relative ranking aid**, not an objective measure of artistic value.

#### iOS 18 and later

When available, CapturePilot uses Apple's Vision image-aesthetics observation as one signal.

Base weights:

| Signal | Weight |
| --- | ---: |
| Exposure heuristic | 26% |
| Composition heuristic | 28% |
| Detail heuristic | 22% |
| Vision aesthetics signal | 24% |

Apple Vision's aesthetics `overallScore` is returned from -1 to 1. CapturePilot maps that range linearly to 0–100 before combining it with the other signals.

If Vision marks an image as a utility image, CapturePilot currently applies a small 4-point ranking penalty. Utility does not mean the image is technically bad; it means Vision considers it less memorable/exciting for the aesthetics task.

#### iOS 17 fallback

When the Vision aesthetics request is unavailable:

| Signal | Weight |
| --- | ---: |
| Exposure heuristic | 32% |
| Composition heuristic | 38% |
| Detail heuristic | 30% |

#### Portrait adjustment

If face capture quality is available and the photo is classified as Portrait:
- the existing weights are scaled to 86%;
- face capture quality contributes 14%.

### Exposure heuristic

CapturePilot analyzes a reduced grayscale representation and estimates:

- average luminance;
- near-white clipping;
- near-black clipping.

This is a post-shot heuristic and is **not a sensor-linear RAW histogram or calibrated exposure measurement**.

### Composition heuristic

CapturePilot asks Vision for attention-based saliency.

The current composition metric rewards:
- a salient subject near a rule-of-thirds intersection; or
- a deliberately centered salient subject.

This is only one composition model. Centering, symmetry, negative space and other intentional choices can be excellent even when the heuristic gives a lower number.

### Detail heuristic

A reduced grayscale image is analyzed for local edge energy.

This is useful for ranking probable sharpness/detail, but it does not fully separate:
- intentional motion blur;
- shallow depth of field;
- noise;
- texture;
- oversharpening.

### Recommendations

The post-shot Coach can suggest up to four actionable ideas.

Current recommendation families include:

- reduce highlights;
- increase exposure carefully;
- stabilize/refocus;
- simplify the background;
- move toward a stronger compositional point;
- reduce headroom;
- strengthen or intentionally break symmetry;
- use leading lines;
- try a lower automotive angle;
- add a foreground layer;
- wait for better street separation/gesture;
- use negative space;
- protect point highlights at night;
- try a different viewpoint.

Recommendations are suggestions for experimentation, not mandatory corrections.

### Social eligibility

Imported images participate fully in the **private local ranking**.

Only entries whose source is a real CapturePilot capture are eligible to sync their best score into the friends leaderboard.

This reduces obvious leaderboard abuse, but CapturePilot 0.8 is still **not an anti-cheat-certified competition system**.

### Privacy

Ranking analysis runs on-device.

CapturePilot's local ranking store contains thumbnails and analysis metadata. It does not need to upload photo pixels for local ranking.

See [SOCIAL_COMPETITION.md](SOCIAL_COMPETITION.md) for the optional friends score layer.

### Physical validation gates

Before considering Rankings fully validated:

- analyze HEIF, JPEG, Bayer RAW and ProRAW captures;
- compare RAW rendering behavior against processed JPEG ranking;
- verify orientation in portrait/landscape/upside-down;
- test 50-photo import batches;
- test duplicate prevention;
- validate category classifications against a varied real photo set;
- compare iOS 17 fallback rankings against iOS 18+ aesthetics-assisted rankings;
- inspect false positives for detail/blur/noise;
- test ranking persistence after relaunch/reboot;
- verify delete removes only CapturePilot's local ranking entry/thumbnail;
- measure memory and thermal behavior for repeated high-resolution analysis.

---

## Español

CapturePilot 0.8 agrega un sistema privado de revisión y ranking posterior al disparo.

El objetivo no es declarar qué fotografía es artísticamente "mejor" de forma objetiva. El objetivo es comparar tus propias imágenes con criterios consistentes, encontrar tomas fuertes con rapidez, filtrar por categoría y recibir ideas concretas para un segundo intento.

### Qué entra al Ranking

CapturePilot puede analizar:

1. **nuevas capturas hechas en CapturePilot** automáticamente;
2. **imágenes elegidas por el usuario** mediante el selector de Fotos.

De una importación CapturePilot no conserva una copia completa del original dentro del ranking. Guarda:
- miniatura JPEG;
- métricas;
- categoría;
- tags;
- recomendaciones;
- fecha/origen;
- fingerprint SHA-256 para evitar duplicados.

### Interfaz

La sección Ranking permite:

- Top 5;
- Top 10;
- Top 25;
- Top 50;
- todas las categorías o una categoría concreta;
- revisión individual;
- eliminar del Ranking sin borrar la fotografía original de Fotos.

Categorías actuales:

- General
- Retrato
- Arquitectura
- Automotriz
- Macro
- Calle
- Paisaje
- Noche

### Clasificación automática

La clasificación post-shot intenta usar primero la información real de la imagen.

Orden actual:

1. rostro detectado → Retrato;
2. luminancia promedio muy baja → Noche;
3. clasificaciones de Vision para Automotriz, Arquitectura, Paisaje, Macro o Calle;
4. si la imagen es ambigua, el modo de escena seleccionado puede actuar como fallback;
5. en otro caso → General.

Es una heurística; una fotografía puede pertenecer razonablemente a más de un género.

### Coach Score

Cada fotografía recibe un **Coach Score de 0–100**.

Es una ayuda de ranking relativo, no una medida objetiva de valor artístico.

#### iOS 18+

Cuando está disponible se añade la señal de estética de Apple Vision.

Pesos base:

| Señal | Peso |
| --- | ---: |
| Exposición heurística | 26% |
| Composición heurística | 28% |
| Detalle heurístico | 22% |
| Señal estética Vision | 24% |

Vision entrega `overallScore` entre -1 y 1; CapturePilot lo transforma linealmente a 0–100.

Si Vision marca una imagen como utility, se resta actualmente una pequeña penalización de 4 puntos. Utility no significa necesariamente mala calidad técnica.

#### Fallback iOS 17

| Señal | Peso |
| --- | ---: |
| Exposición | 32% |
| Composición | 38% |
| Detalle | 30% |

#### Retrato

Cuando existe face capture quality y la categoría es Retrato:
- las señales anteriores ocupan 86%;
- calidad de captura de rostro aporta 14%.

### Recomendaciones

El Coach post-shot puede mostrar hasta cuatro sugerencias, por ejemplo:

- proteger altas luces;
- abrir exposición;
- estabilizar/refocalizar;
- simplificar fondo;
- mover el encuadre;
- reducir headroom;
- reforzar simetría;
- usar líneas guía;
- probar un ángulo más bajo en automotriz;
- añadir primer plano;
- esperar mejor separación en calle;
- usar espacio negativo;
- proteger luces nocturnas;
- cambiar altura/distancia/punto de vista.

Son propuestas para experimentar, no correcciones obligatorias.

### Elegibilidad social

Las imágenes importadas participan completamente en el ranking privado.

Sólo las fotografías **capturadas realmente dentro de CapturePilot** pueden sincronizar sus mejores scores al ranking de amigos.

Aun así, 0.8 no pretende ser un sistema anti-cheat certificado.

### Privacidad

El análisis del ranking es local.

CapturePilot guarda miniaturas y metadata de análisis para el ranking privado; no necesita subir píxeles para esta función.

Consulta [SOCIAL_COMPETITION.md](SOCIAL_COMPETITION.md).

### Validación pendiente

Antes de considerarlo validado:

- HEIF/JPEG/RAW/ProRAW reales;
- orientación;
- lotes de 50 importaciones;
- duplicados;
- clasificación con dataset fotográfico diverso;
- comparación iOS 17 vs iOS 18+;
- detalle vs blur/noise;
- persistencia tras reinicio;
- borrado local;
- memoria/temperatura con análisis repetido.
