# App Store / TestFlight Metadata Draft

## English

**Name:** CapturePilot

**Beta Description:**
CapturePilot 0.10 adds Creative Spark, an optional ✦ scan for temporary creative block. It analyzes one live frame, marks evidence-backed points of interest when available, and offers exploratory framing/light/depth ideas without changing camera settings.


CapturePilot 0.10 includes private Rankings: automatic post-shot analysis, Top 5/10/25/50, category filters, Coach Score breakdowns, and per-photo suggestions. Private Rankings remain available without an account. Account & Friends is optional and supports Apple or Google when the Firebase backend is configured.


CapturePilot 0.10 includes RAW + Share JPEG and adds a persistent LUT library. On supported high-resolution camera configurations, one shutter request captures RAW/ProRAW plus a processed companion. The RAW remains untouched while CapturePilot can generate a 12/24/48 MP-target JPEG, optionally using a 3D .cube LUT from the photographer's authorized library, and expose it to the iOS Share Sheet.

  
CapturePilot is a free, ad-free iPhone camera with professional manual controls and an on-device photography coach. The current beta adds dual-level Zebra exposure warnings, RGB histogram, False Color, Luma Waveform, RGB Parade, Vectorscope, configurable Focus Peaking, AF/AE Lock, clipping warnings, and photographic frame guides. The current beta includes capability-gated HEIF/HEVC, JPEG, Bayer RAW and Apple ProRAW, hardware-derived photo resolutions, physical lens switching, manual exposure/focus/white balance, Focus Peaking, customizable HUD, adaptive orientation, composition guides, leading-line/symmetry/vanishing-point/negative-space analysis, and scene-specific coaching for Portrait, Architecture, Automotive, Macro, Street, Landscape and Night.

CapturePilot 0.10 also adds a persistent LUT library from a user-selected Files folder. The on-device Coach can optionally suggest a LUT based on scene/exposure signals and measured LUT-transform characteristics; the photographer must explicitly apply it.

**What to Test:**
For Creative Spark, test real windows/doorways/rectangular structures as frame-within-frame candidates and verify that foreground markers only appear when lower-frame detail/contrast supports them.


Test Creative Spark in every orientation and physical lens. Verify marker alignment, aspect-fill crop, rescan/dismiss, low-signal scenes, and that no exposure/focus/lens/LUT/crop changes happen automatically.


Test automatic ranking, imports, Top filters, category inference, per-photo recommendations, and RAW/ProRAW handling. Also verify that the app opens directly to the camera with no account configured. When the account backend is configured, test Apple, Google, provider linking, friends, score opt-in, and account deletion.

  
Test the resolutions and formats that your device actually exposes, RAW+JPG output, LUT-folder persistence/refresh, explicit Coach LUT recommendation/apply behavior, physical lens switching, manual controls, orientation/session recovery, HUD persistence, Focus Peaking alignment, professional monitoring, composition guides, and each scene coach. Include iPhone model, iOS version, and File Provider when relevant.

**Privacy Summary:**  
Core photography and private Rankings require no account. No ads, third-party analytics, or tracking. The optional account feature uses Firebase Authentication and Firestore only after the user opens Account & Friends and signs in; Friends does not upload photos. Live analysis, scopes, LUT parsing/profiling, LUT recommendation, and Share-JPEG LUT processing run on-device. External LUT folders are accessed only after the photographer selects one through the system Files picker.

---

## Español

**Nombre:** CapturePilot

**Descripción beta:**
CapturePilot 0.10 agrega Chispa creativa, un scan ✦ opcional para bloqueos creativos momentáneos. Analiza un frame, marca puntos con evidencia cuando existen y propone ideas de encuadre/luz/profundidad sin cambiar parámetros de cámara.


CapturePilot 0.10 incluye Ranking privado: análisis post-shot automático, Top 5/10/25/50, filtros, desglose Coach Score y sugerencias por fotografía. El Ranking privado sigue disponible sin cuenta. Cuenta y amigos es opcional y admite Apple o Google cuando Firebase está configurado.


CapturePilot 0.10 incluye RAW + JPEG para compartir y agrega una biblioteca LUT persistente. En configuraciones compatibles de alta resolución, un solo request captura RAW/ProRAW y un companion procesado. El RAW queda intacto y CapturePilot puede crear un JPEG objetivo 12/24/48 MP usando opcionalmente un LUT 3D .cube de la biblioteca autorizada por el fotógrafo, con acceso directo a Share Sheet.

  
CapturePilot es una cámara gratuita y sin anuncios con controles manuales y coach local. La beta incluye HEIF/HEVC, JPEG, Bayer RAW y Apple ProRAW condicionados por el hardware, resoluciones derivadas del dispositivo, lentes físicas, exposición/enfoque/WB manual, Focus Peaking, HUD personalizable, orientación adaptativa, guías y análisis de líneas/simetría/punto de fuga/espacio negativo, además de coaches para Retrato, Arquitectura, Automotriz, Macro, Calle, Paisaje y Noche.

CapturePilot 0.10 también agrega una biblioteca LUT persistente desde una carpeta seleccionada en Archivos. El Coach puede sugerir opcionalmente un LUT según escena/exposición y características medidas del transform; el fotógrafo debe aplicarlo explícitamente.

**Qué probar:**
En Chispa creativa prueba ventanas/puertas/estructuras rectangulares como frame-within-frame y confirma que el primer plano sólo aparece cuando existe detalle/contraste real en la parte baja.


Prueba Chispa creativa en todas las orientaciones y lentes. Verifica alineación, aspect-fill, reescaneo/cierre, escenas con poca señal y que nunca cambie exposición/foco/lente/LUT/crop automáticamente.


Prueba ranking automático, importaciones, Tops, categorías, recomendaciones y RAW/ProRAW. Confirma también que la app entra directamente a cámara sin cuenta. Con backend configurado prueba Apple, Google, vinculación, amistades, opt-in de score y eliminación de cuenta.

  
Prueba resoluciones/formatos reales, salida RAW+JPG, persistencia/refresh de la carpeta LUT, recomendación/aplicación explícita de LUT por el Coach, lentes, controles manuales, recuperación de sesión/orientación, HUD, Focus Peaking, monitoreo profesional, guías y cada Coach. Incluye modelo de iPhone, versión de iOS y File Provider cuando aplique.

**Privacidad:**  
La cámara y el Ranking privado no requieren cuenta. Sin anuncios, analítica de terceros ni tracking. La cuenta opcional usa Firebase Authentication y Firestore sólo después de entrar a Cuenta y amigos e iniciar sesión; Amigos no sube fotografías. Análisis, scopes, parseo/perfilado LUT, recomendaciones y aplicación del LUT al JPEG funcionan localmente. Las carpetas LUT externas sólo se leen después de que la persona seleccione una mediante el selector de Archivos.
