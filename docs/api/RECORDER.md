# Recorder de respuestas crudas — cómo usarlo

> **Objetivo:** capturar las respuestas de la API interna de YouTube Music a disco para poder estudiarlas offline con calma, en lugar de intentar debuggear con `flutter logs` en tiempo real.

## Activación

Tienes dos formas de activarlo:

### Opción A: build flag (recomendado para depuración profunda)
```bash
flutter run --dart-define=RECORD_API=true
# o para release:
flutter build apk --dart-define=RECORD_API=true
```

### Opción B: variable en runtime
```dart
import 'package:harmonymusic/utils/response_recorder.dart';
ResponseRecorder.enabled = true;
```
(Útil si quieres un toggle en la pantalla de Settings, lo cual es un buen siguiente paso.)

## Dónde se guardan

```
<app docs dir>/api_recordings/<session-id>/
  _manifest.json
  2026-06-23T18-42-12-345Z-search-unfiltered-req.txt
  2026-06-23T18-42-12-345Z-search-unfiltered-req.json
  2026-06-23T18-42-12-345Z-search-unfiltered-res.txt
  2026-06-23T18-42-12-345Z-search-unfiltered-res.json
  ...
```

**Cómo encontrar el directorio:**

En Android, el recorder escribe en el *external files dir* de la app, que es accesible vía `adb pull` **sin** `run-as` y **sin** necesidad de frenar la app:

```
/sdcard/Android/data/com.harmonymusic/files/api_recordings/<session>/
```

**Comandos para extraer los archivos:**

```bash
# Opción 1: adb pull directo (RECOMENDADO — no requiere run-as, no frena la app)
adb pull /sdcard/Android/data/com.harmonymusic/files/api_recordings/ ./recordings

# Opción 2: tar a través de adb (sin run-as)
adb shell "cd /sdcard/Android/data/com.harmonymusic/files && tar -cf - api_recordings" > recordings.tar

# Opción 3: solo listar los archivos (para ver qué hay)
adb shell ls /sdcard/Android/data/com.harmonymusic/files/api_recordings/

# Opción 4: filtrar por endpoint
adb shell ls /sdcard/Android/data/com.harmonymusic/files/api_recordings/ | grep search
```

En Linux/Windows/Mac (cuando corras `flutter run` en desktop), el recorder cae en `<app data>/api_recordings/`.

**Tip:** la app loguea la ruta exacta al arrancar (busca `[Recorder] Writing captures to:` en `flutter logs`).

## Formato de cada archivo

### `*req.txt` (request)
```
POST https://music.youtube.com/youtubei/v1/search?prettyPrint=false&alt=json&key=...

--- HEADERS ---
{
  "accept": "*/*",
  "accept-encoding": "gzip, deflate",
  "content-encoding": "gzip",
  "content-type": "application/json",
  "cookie": "CONSENT=YES+1",
  "origin": "https://music.youtube.com",
  "user-agent": "Mozilla/5.0 (...)",
  "x-goog-visitor-id": "CgttN24w..."
}

--- BODY ---
{
  "context": { ... },
  "query": "bruno mars"
}
```

### `*res.txt` (response)
```
POST https://music.youtube.com/youtubei/v1/search?...
Status: 200
Elapsed: 1047ms

--- HEADERS ---
{
  "content-type": "application/json; charset=UTF-8",
  ...
}

--- BODY ---
{
  "responseContext": { ... },
  "contents": {
    "tabbedSearchResultsRenderer": {
      "tabs": [ ... ]
    }
  }
}
```

### `*req.json` y `*res.json` (metadata)
Solo un resumen pequeño: timestamp, endpoint, variant, statusCode, bodySizeChars, bodyPreview. Sirve para indexar sin abrir los txt.

## Límites de retención

- **200 archivos por sesión** (configurable vía `ResponseRecorder.maxFilesPerSession`).
- Cuando se llega al límite, los más viejos se eliminan automáticamente.
- Cada sesión se identifica por timestamp UTC en el nombre de la carpeta — puedes borrar sesiones enteras sin miedo.

## Filtrado por endpoint

Los archivos se nombran como:
```
<timestamp>-<endpoint>-<variant>-<kind>.txt
```

Donde:
- `endpoint`: `search`, `browse`, `next`, `player`, `music/get_search_suggestions`
- `variant`: para search, `unfiltered` vs `songs`/`videos`/`albums`/`artists`/`playlists`. Para browse, el `browseId`. Para otros, `default`.
- `kind`: `req`, `res`, `err`

Para depurar el bug de previews de artistas:
```bash
adb shell run-as com.harmonymusic ls app_flutter/api_recordings/ | grep search | grep unfiltered
```

## Qué buscar en los archivos

1. **Compara `unfiltered-res.txt` con `songs-res.txt`** — la diferencia de tamaño te dice cuánto se ahorra.
2. **En el response unfiltered**, busca `sectionListRenderer.contents` y mira qué tipos de renderer hay. Ya sabemos que el primero es `musicCardShelfRenderer` y los otros 26 son `itemSectionRenderer`. La pregunta es: ¿qué hay DENTRO de cada `itemSectionRenderer.contents`?
3. **Busca campos `count`, `numResults`, `maxResults`**, `params` con segmentos numéricos, o cualquier otro campo que controle tamaño. Si lo encuentras, el fix es trivial.
4. **Captura varias queries** ("bruno mars", "metallica", "shake it off") y compara. A veces YouTube Music devuelve diferentes shapes de respuesta según el query.
