# TestFlight Release Guide / Guía de publicación en TestFlight

## English

### Candidate

CapturePilot 0.8.0 build 8 compiles in Release for iOS Simulator and iPhoneOS in GitHub Actions.

The candidate includes capability-driven HEIF/RAW/ProRAW, maximum photo dimensions, RAW + Share JPEG, 12/24/48 MP share targets without upscaling, resolution selection, adaptive physical lens switching, manual controls, local geometric coaching, eight scene coach modes, professional monitoring/scopes, adaptive orientation, customizable HUD, and Focus Peaking.

The candidate also includes a persistent LUT library, private Top 5/10/25/50 Rankings with post-shot Coach review, and an optional iCloud/CloudKit friends-score layer that does not upload photos.

Compilation does not prove physical camera behavior, external File Provider persistence, ranking quality, CloudKit production configuration, or App Store acceptance.

### Before Archive

Complete the physical checklists in:

- `docs/TESTING.md`
- `docs/UI_LAYOUT.md`

At minimum use:

- one recent Pro iPhone capable of ProRAW/high-resolution capture;
- one smaller/notched or otherwise different-layout iPhone when available.

Record actual dimensions for every resolution shown.

### LUT library acceptance

Before Archive, test at least:

- select a LUT folder under On My iPhone;
- select a LUT folder under iCloud Drive;
- relaunch CapturePilot and verify the folder can be reopened;
- add/remove/rename a .cube and verify refresh;
- verify nested folders;
- verify invalid LUTs are not offered;
- apply a LUT recommended by the Coach;
- confirm the RAW remains unaffected and the Share JPEG uses the selected LUT;
- confirm the recommendation is never applied automatically.

If a third-party File Provider is available, test it separately and record provider/app version.

### Rankings acceptance

Before Archive, verify on a physical iPhone:

- automatic ranking after a CapturePilot HEIF/JPEG capture;
- RAW/ProRAW ranking without crash;
- RAW+JPG creates one ranking entry from the processed share JPEG;
- Top 5/10/25/50;
- every category filter;
- imported photos remain local;
- iOS 18+ shows Vision aesthetics as supplemental information without changing the cross-version Coach Score formula;
- recommendations are sensible on a varied real photo set.

### Friends/social acceptance

The social layer requires Apple Developer + CloudKit configuration beyond source code.

Before considering it TestFlight-ready:

- enable iCloud + CloudKit for `com.tiburonns.CapturePilot`;
- create/use `iCloud.com.tiburonns.CapturePilot`;
- exercise the development schema;
- add required QUERYABLE indexes;
- deploy the tested schema for distribution;
- verify the provisioning profile carries the iCloud/CloudKit entitlements;
- test with two real iCloud accounts/devices;
- confirm photos/thumbnails never appear in public CloudKit records;
- confirm imported photos never affect shared scores;
- test unavailable/signed-out iCloud state.

See [SOCIAL_COMPETITION.md](SOCIAL_COMPETITION.md).

### Archive

1. Pull latest `main`.
2. Open `CapturePilot.xcodeproj`.
3. Select the paid Apple Developer Team.
4. Confirm Bundle Identifier.
5. Select Generic iOS Device / eligible device.
6. Product > Archive.
7. Organizer > Validate App.
8. Resolve errors and understood warnings.
9. Distribute App > App Store Connect > Upload.

### TestFlight

- Confirm **0.8.0 (8)**.
- Complete export compliance as requested.
- Fill beta description, feedback contact, and review contact.
- Start with Internal Testing.
- Verify HEIF/JPEG/RAW/ProRAW labels match actual output on the test hardware.
- Verify RAW+JPG output dimensions, LUT-library persistence, and Coach LUT recommendation/apply behavior.
- Do not advertise 24/48 MP, ProRAW, telephoto, or manual modes on devices where CapturePilot does not expose those capabilities.

---

## Español

### Candidato

CapturePilot 0.8.0 build 8 compila en Release para Simulator e iPhoneOS mediante GitHub Actions.

Incluye HEIF/RAW/ProRAW condicionados por capability, dimensiones máximas, RAW + JPEG para compartir, objetivos 12/24/48 MP sin upscale, selector de resolución, lentes físicas, controles manuales, análisis geométrico local, ocho coaches de escena, monitoreo profesional/scopes, orientación adaptativa, HUD y Focus Peaking.

El candidato también incluye biblioteca LUT persistente desde una carpeta de Archivos y recomendaciones LUT explicables del Coach.

Compilar no demuestra comportamiento físico, persistencia de File Providers externos, calidad de recomendaciones ni aceptación de App Store.

### Antes del Archive

Completa:

- `docs/TESTING.md`
- `docs/UI_LAYOUT.md`

Usa al menos un iPhone Pro reciente capaz de ProRAW/alta resolución y, cuando sea posible, otro modelo con geometría de pantalla distinta.

Registra las dimensiones reales de cada resolución mostrada.

### Aceptación de biblioteca LUT

Antes del Archive prueba al menos:

- seleccionar carpeta LUT en En mi iPhone;
- seleccionar carpeta LUT en iCloud Drive;
- relanzar CapturePilot y comprobar que puede reabrirla;
- agregar/eliminar/renombrar un .cube y comprobar refresh;
- verificar subcarpetas;
- comprobar que LUT inválidos no se ofrecen;
- aplicar un LUT recomendado por el Coach;
- confirmar que RAW no cambia y el JPEG para compartir usa el LUT activo;
- confirmar que la recomendación nunca se aplica automáticamente.

Si existe un File Provider de terceros, pruébalo por separado y registra proveedor/versión.

### Aceptación del Ranking

Antes del Archive verifica en iPhone real:

- ranking automático tras captura HEIF/JPEG;
- RAW/ProRAW sin crash;
- RAW+JPG crea una sola entrada desde el JPEG procesado;
- Top 5/10/25/50;
- filtros por categoría;
- importaciones permanecen locales;
- iOS 18+ muestra estética Vision como información suplementaria sin cambiar la fórmula comparable del Coach Score;
- recomendaciones razonables con fotos reales diversas.

### Aceptación social

La capa social requiere configuración Apple Developer/CloudKit adicional al código.

Antes de considerarla lista para TestFlight:

- activar iCloud + CloudKit para `com.tiburonns.CapturePilot`;
- usar `iCloud.com.tiburonns.CapturePilot`;
- crear/probar schema de desarrollo;
- añadir índices QUERYABLE;
- desplegar schema para distribución;
- verificar entitlements en provisioning;
- probar con dos cuentas/dispositivos iCloud;
- confirmar que nunca se suben fotos/miniaturas;
- confirmar que importaciones no cambian scores compartidos;
- probar iCloud no disponible/cierre de sesión.

Consulta [SOCIAL_COMPETITION.md](SOCIAL_COMPETITION.md).

### Archive

1. Actualiza `main`.
2. Abre `CapturePilot.xcodeproj`.
3. Selecciona tu Team de pago.
4. Confirma Bundle Identifier.
5. Selecciona Generic iOS Device/dispositivo válido.
6. Product > Archive.
7. Organizer > Validate App.
8. Corrige errores y revisa warnings.
9. Distribute App > App Store Connect > Upload.

### TestFlight

- Confirma **0.8.0 (8)**.
- Completa export compliance.
- Completa descripción beta y contactos.
- Empieza con Internal Testing.
- Comprueba que HEIF/JPEG/RAW/ProRAW coincidan con el archivo real.
- Verifica dimensiones RAW+JPG, persistencia de biblioteca LUT y comportamiento de recomendación/aplicación del Coach.
- No anuncies 24/48 MP, ProRAW, telefoto o controles manuales en hardware donde CapturePilot no los exponga.
