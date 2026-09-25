# Privacy / Privacidad

## English

CapturePilot's current source does not create an account, serve ads, include third-party analytics, or upload camera frames to a CapturePilot server.

### Protected resources used

- Camera: live viewfinder, local coach analysis, photo capture.
- Photo Library add-only: save a captured photo.

### Privacy Manifest

`PrivacyInfo.xcprivacy` declares:

- Tracking: false.
- Tracking domains: none.
- Collected data types: none.
- Required Reason API: UserDefaults with reason `CA92.1`, used only for app-local settings such as language, grid, and coach intensity.

If a future feature introduces networking, analytics, crash SDKs, cloud AI, accounts, or additional Required Reason APIs, this document and the manifest must be updated before release.

## Español

El código actual de CapturePilot no crea cuentas, no sirve publicidad, no incluye analítica de terceros y no sube frames de cámara a un servidor de CapturePilot.

### Recursos protegidos utilizados

- Cámara: visor, análisis local del coach y captura.
- Fototeca con permiso solo para agregar: guardar fotografías capturadas.

### Privacy Manifest

`PrivacyInfo.xcprivacy` declara:

- Tracking: falso.
- Dominios de tracking: ninguno.
- Tipos de datos recopilados: ninguno.
- Required Reason API: UserDefaults con motivo `CA92.1`, utilizado únicamente para ajustes locales de la app como idioma, guía y nivel del coach.

Si en el futuro se agregan red, analítica, SDK de crashes, IA en la nube, cuentas u otras Required Reason APIs, el manifiesto y este documento deberán actualizarse antes de publicar.
