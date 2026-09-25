# App Store / TestFlight Metadata Draft

## English

**Name:** CapturePilot

**Beta Description:**
CapturePilot 0.7 includes RAW + Share JPEG and adds a persistent LUT library. On supported high-resolution camera configurations, one shutter request captures RAW/ProRAW plus a processed companion. The RAW remains untouched while CapturePilot can generate a 12/24/48 MP-target JPEG, optionally using a 3D .cube LUT from the photographer's authorized library, and expose it to the iOS Share Sheet.

  
CapturePilot is a free, ad-free iPhone camera with professional manual controls and an on-device photography coach. The current beta adds dual-level Zebra exposure warnings, RGB histogram, False Color, Luma Waveform, RGB Parade, Vectorscope, configurable Focus Peaking, AF/AE Lock, clipping warnings, and photographic frame guides. The current beta includes capability-gated HEIF/HEVC, JPEG, Bayer RAW and Apple ProRAW, hardware-derived photo resolutions, physical lens switching, manual exposure/focus/white balance, Focus Peaking, customizable HUD, adaptive orientation, composition guides, leading-line/symmetry/vanishing-point/negative-space analysis, and scene-specific coaching for Portrait, Architecture, Automotive, Macro, Street, Landscape and Night.

CapturePilot 0.7 also adds a persistent LUT library from a user-selected Files folder. The on-device Coach can optionally suggest a LUT based on scene/exposure signals and measured LUT-transform characteristics; the photographer must explicitly apply it.

**What to Test:**  
Test the resolutions and formats that your device actually exposes, RAW+JPG output, LUT-folder persistence/refresh, explicit Coach LUT recommendation/apply behavior, physical lens switching, manual controls, orientation/session recovery, HUD persistence, Focus Peaking alignment, professional monitoring, composition guides, and each scene coach. Include iPhone model, iOS version, and File Provider when relevant.

**Privacy Summary:**  
No account, ads, third-party analytics, tracking, or CapturePilot cloud upload. Live analysis, scopes, LUT parsing/profiling, LUT recommendation, and Share-JPEG LUT processing run on-device. External LUT folders are accessed only after the photographer selects one through the system Files picker.

---

## Español

**Nombre:** CapturePilot

**Descripción beta:**
CapturePilot 0.7 incluye RAW + JPEG para compartir y agrega una biblioteca LUT persistente. En configuraciones compatibles de alta resolución, un solo request captura RAW/ProRAW y un companion procesado. El RAW queda intacto y CapturePilot puede crear un JPEG objetivo 12/24/48 MP usando opcionalmente un LUT 3D .cube de la biblioteca autorizada por el fotógrafo, con acceso directo a Share Sheet.

  
CapturePilot es una cámara gratuita y sin anuncios con controles manuales y coach local. La beta incluye HEIF/HEVC, JPEG, Bayer RAW y Apple ProRAW condicionados por el hardware, resoluciones derivadas del dispositivo, lentes físicas, exposición/enfoque/WB manual, Focus Peaking, HUD personalizable, orientación adaptativa, guías y análisis de líneas/simetría/punto de fuga/espacio negativo, además de coaches para Retrato, Arquitectura, Automotriz, Macro, Calle, Paisaje y Noche.

CapturePilot 0.7 también agrega una biblioteca LUT persistente desde una carpeta seleccionada en Archivos. El Coach puede sugerir opcionalmente un LUT según escena/exposición y características medidas del transform; el fotógrafo debe aplicarlo explícitamente.

**Qué probar:**  
Prueba resoluciones/formatos reales, salida RAW+JPG, persistencia/refresh de la carpeta LUT, recomendación/aplicación explícita de LUT por el Coach, lentes, controles manuales, recuperación de sesión/orientación, HUD, Focus Peaking, monitoreo profesional, guías y cada Coach. Incluye modelo de iPhone, versión de iOS y File Provider cuando aplique.

**Privacidad:**  
Sin cuenta, anuncios, analítica de terceros, tracking ni nube de CapturePilot. Análisis, scopes, parseo/perfilado LUT, recomendaciones y aplicación del LUT al JPEG funcionan localmente. Las carpetas LUT externas sólo se leen después de que la persona seleccione una mediante el selector de Archivos.
