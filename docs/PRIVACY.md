# Privacy / Privacidad

## English

CapturePilot does not create an account, serve ads, include third-party analytics, or upload camera frames to a CapturePilot server.

### Protected resources

- Camera: live viewfinder, local coach/geometric analysis, Focus Peaking, and photo capture.
- Photo Library add-only: save photos explicitly captured by the user.

### Local processing

The following run on-device:

- Vision face/person/saliency/horizon requests;
- luminance and clipping sampling;
- leading-line / symmetry / vanishing-point / negative-space heuristics;
- Focus Peaking edge analysis.

No networking dependency is required for these features.

### Local preferences

UserDefaults stores app-local settings such as language, guide, coach intensity/scene, orientation policy, and HUD layout.

`PrivacyInfo.xcprivacy` declares:

- Tracking: false.
- Tracking domains: none.
- Collected data types: none.
- Required Reason API: UserDefaults / CA92.1.

If networking, accounts, analytics, crash SDKs, cloud AI, or additional Required Reason APIs are added later, this document and the manifest must be reviewed before release.

---

## Español

CapturePilot no crea cuenta, no sirve publicidad, no incluye analítica de terceros y no sube frames de cámara a un servidor de CapturePilot.

### Recursos protegidos

- Cámara: visor, coach/análisis geométrico local, Focus Peaking y captura.
- Fototeca add-only: guardar fotos tomadas explícitamente por la persona.

### Procesamiento local

Se ejecutan localmente:

- Vision para rostro/persona/saliencia/horizonte;
- luminancia y clipping;
- líneas/simetría/punto de fuga/espacio negativo;
- Focus Peaking.

No requieren una dependencia de red.

### Preferencias

UserDefaults conserva idioma, guía, intensidad/escena del coach, orientación y HUD.

`PrivacyInfo.xcprivacy` declara:

- Tracking: falso.
- Dominios: ninguno.
- Tipos de datos recopilados: ninguno.
- Required Reason API: UserDefaults / CA92.1.

Si en el futuro se agregan red, cuentas, analytics, SDK de crashes, IA cloud u otras Required Reason APIs, se debe revisar este documento y el manifest.
