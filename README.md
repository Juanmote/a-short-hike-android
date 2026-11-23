# A Short Hike – port para Android

Port no oficial de **A Short Hike** (adamgryu) para consolas y móviles Android (arm64),
con mando físico, controles táctiles, vibración, logros, filtros de imagen y más.

**Este repositorio no contiene el juego.** Para jugar necesitas tu propia copia de A Short Hike.
Cómpralo y apoya a su creador: [itch.io](https://adamgryu.itch.io/a-short-hike) ·
[Steam](https://store.steampowered.com/app/1055540/A_Short_Hike/)

Port: **Juanmote**. Juego original: **adamgryu** (Adam Robinson-Yu). Este proyecto no está afiliado al autor del juego.

## Versiones del juego que valen

| Copia | Versión | Estado |
|---|---|---|
| **itch.io, versión de Linux** | 1.10.2 | ✅ Probada (es con la que se hizo el port) |
| **Steam, versión de Windows** | 1.10.2 | ✅ Probada |
| itch.io Windows/Mac, GOG, Epic, Steam Linux/Mac | – | ❓ Sin probar. La APK avisa si los archivos no coinciden |

Para saber la versión: en el menú principal del juego aparece abajo a la derecha.

## Qué trae el port

### Adaptación a Android
- APK arm64 (Android 7 o superior), horizontal y a pantalla completa.
- Se ajusta a cualquier relación de aspecto, también 4:3, 8:7 y 1:1 (los menús se ven enteros).
- 30, 60 o 120 fps (Opciones › Gráficos). Con 120 se pide a la pantalla que funcione a 120 Hz.
- Las partidas y opciones se guardan en la consola (sin Steam).
- Gráficos corregidos para Android (shaders reconstruidos para OpenGL ES 3).
- Música y fuentes japonesas, chinas, coreanas y cirílicas funcionando sin Addressables.
- Icono propio (normal, redondo y adaptativo).

### Mandos físicos
- Funciona con el mando integrado de las consolas y con mandos externos (mapeo Android estándar).
- Probado en AYN Odin 3 y Retroid Pocket Classic / Rotate.

### Controles táctiles (Opciones › Controles)
- Cruceta y botones A/B/X/Y propios: semitransparentes en reposo; al pulsar, el botón (o la dirección
  de la cruceta) se ilumina.
- Mostrar: sí, no o **automático** (se ocultan al usar un mando y vuelven al tocar la pantalla).
- Tamaño (75 %–150 %) y opacidad (20 %–75 %).

### Vibración (Opciones › Controles)
- Vibra la consola y el mando si tiene motor: pesca (picada, tirones, captura), aleteo, saltos,
  chapuzones, pala, cofres, objetos recogidos, voleibol y logros.

### Imagen (Opciones › Gráficos)
- Filtros **Scanlines** y **CRT**.
- Colores **Tele antigua**, **Vivos**, **Nocturna**, **Sepia** y **Pantalla verde**.

### Logros
- Se guardan en la consola y aparece un aviso «¡logro conseguido!» con su icono al conseguirlos.
  Se ven en Opciones › Logros.

### Créditos
- «- ported by juanmote -» en los créditos del menú y en los finales.

## Instalación (APK de Releases)

1. Descarga la APK de la última versión en **[Releases](../../releases/latest)** e instálala.
2. Copia a la consola la carpeta del juego (la que contiene `AShortHike_Data`):
   - **itch.io (Linux)**: descomprime el archivo descargado de itch.io.
   - **Steam (Windows)**: en Steam, clic derecho en el juego › Administrar › Ver archivos locales.
3. Abre el juego, pulsa **Seleccionar carpeta del juego** y elige esa carpeta (vale también la propia `AShortHike_Data`).
4. Espera a que se preparen los datos (necesita unos 700 MB libres). Solo se hace la primera vez;
   al actualizar la APK se repite solo.

La APK no lleva gráficos, música, sonidos ni fuentes del juego: los coge de tu copia al prepararlos.
Si tus archivos no coinciden con ninguna de las versiones admitidas, el juego avisa.
Después puedes borrar la carpeta copiada.

## Alternativa: compilar tu propia APK

Todo se hace desde la web de GitHub; no hace falta instalar nada. La APK se compila en los
servidores de GitHub (gratis) con tus archivos del juego, y lleva los datos dentro (no hace falta
seleccionar carpeta).

1. **Haz una copia privada de este repositorio.** Pulsa **Use this template › Create a new repository**
   y marca **Private**. Tiene que ser privada: los archivos del juego no se pueden publicar
   (el proceso se niega a funcionar en un repositorio público).
2. **Crea una cuenta gratuita de Unity** en <https://id.unity.com> si no la tienes. Hace falta para compilar.
3. En tu copia: **Settings › Secrets and variables › Actions › New repository secret** y crea:
   - `UNITY_EMAIL`: el correo de tu cuenta de Unity
   - `UNITY_PASSWORD`: su contraseña
4. **Sube los archivos del juego.** Comprime en un `.zip` o `.7z` todo lo que hay en la carpeta del juego
   (`AShortHike_Data` y lo demás; vale también el archivo tal cual lo descargaste de itch.io)
   y súbelo de una de estas formas:
   - **Recomendado:** en tu copia, **Releases › Create a new release**, etiqueta `juego`, y adjunta el archivo. Admite archivos grandes.
   - Si pesa menos de 25 MB por archivo (por ejemplo, un 7z en volúmenes): súbelo a la carpeta `game/`.
5. **Compila:** pestaña **Actions › Compilar APK › Run workflow**. Tarda entre 30 y 60 minutos.
6. La APK aparece en **Releases** (`A Short Hike Android 1.0.x`). Descárgala desde la consola e instálala.

La primera compilación crea una clave de firma y la guarda en tu copia (`tools/firma/mi.keystore`),
así las siguientes APK se instalan encima sin desinstalar. Si prefieres tu propia clave, añade los secretos
`ANDROID_KEYSTORE_BASE64` (tu keystore en base64), `ANDROID_KEYSTORE_PASS` y, si el alias no es `ash`, `ANDROID_KEY_ALIAS`.

Si la compilación falla, descarga los **registros** de esa ejecución (al final de la página de la ejecución)
y mira `errores.txt` y `licencia.txt`.

## Cómo funciona la APK de Releases

- Se compila con Unity en modo *split binary*: la APK solo lleva el código y una escena de arranque vacía,
  y el resto de datos va en una OBB.
- `tools/make_generic.py` convierte esa OBB en un «molde» con todo lo que viene del juego (texturas, audio
  y fuentes, también los de los bundles de Addressables) puesto a cero, más un manifiesto por cada versión
  admitida con las órdenes para rellenarlo. Moldes y manifiestos van dentro de la APK.
- Al abrirla, `ASHSetupActivity` pide la carpeta del juego, reconoce la versión, descomprime los bundles
  de música y fuentes (`ASHBundle`) y `ASHObbBuilder` rellena el molde con tus archivos (comprobando cada
  archivo con su CRC). La OBB se guarda en `Android/obb/com.juanmote.ashorthike/`.
- Dentro de la APK quedan la estructura de los niveles (escenas y modelos), los gráficos propios del port y una
  sola textura del juego (`Dirt`), que en PC va en un formato comprimido que la consola no puede convertir.

## Cómo funciona por dentro (compilación propia)

1. Se extrae el proyecto Unity de tu copia del juego con [AssetRipper](https://github.com/AssetRipper/AssetRipper) 2.0.0.
2. `tools/aplicar-port.sh` lo convierte en el port:
   - con la copia de Steam, aplica antes `patches/steam-a-itch.patch` (iguala el código con el de itch.io,
     que es más reciente y trae los controles táctiles completos, y quita Steam),
   - aplica `patches/ash-android.patch` (los cambios hechos al código del juego),
   - copia `port/` (todo el código, shaders y gráficos propios del port),
   - renombra los textos del juego a `.txt` y saca la música y las fuentes de los bundles (`tools/extract_aa.py`).
3. Se compila con Unity 2021.3 (IL2CPP, arm64) y se publica la APK en Releases.

| Carpeta | Contenido |
|---|---|
| `port/Assets/Scripts/Assembly-CSharp/` | Código propio: táctil (`ASHTouch`), vibración y FPS (`ASHPort`), filtros (`ASHFilters`), pantallas estrechas (`ASHAspect`), avisos de logros (`ASHAchievementToast`), mando (`AndroidGamepad`), música y fuentes sin Addressables (`AndroidAssetMap`, `AndroidFonts`) |
| `port/Assets/Plugins/Android/` | Vibración y frecuencia de pantalla (`ASHNative`) y pantalla de arranque que genera los datos con tu copia (`ASHSetupActivity`, `ASHObbBuilder`, `ASHBundle`) |
| `port/Assets/Shader/`, `port/Assets/Resources/shaders/` | Shaders reconstruidos para OpenGL ES 3 |
| `port/Assets/Resources/` | Gráficos de los controles táctiles y shader de filtros |
| `patches/` | Cambios al código del juego extraído |
| `tools/` | Aplicación del port, script de compilación y generador de la APK de Releases |
