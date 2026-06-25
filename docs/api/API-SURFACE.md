# API Surface — Harmony-Music (YouTube Music internal)

> **Generado el 2026-06-23** a partir de `lib/services/music_service.dart` y `lib/services/constant.dart`.
> Colección Postman equivalente: [`Harmony-Music-API.postman_collection.json`](./Harmony-Music-API.postman_collection.json)

## Base

| Item | Valor |
| --- | --- |
| Base URL | `https://music.youtube.com/youtubei/v1/` |
| Query params fijos | `?prettyPrint=false&alt=json&key=AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30` |
| Método HTTP | `POST` en todos los endpoints autenticados |
| User-Agent | `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36` |
| Cookie | `CONSENT=YES+1` |
| Origin | `https://music.youtube.com` |
| `X-Goog-Visitor-Id` | **Obligatorio.** Se obtiene al arranque con `genrateVisitorId()` scrapeando `https://music.youtube.com/`. Sin él, los endpoints devuelven 401/403. |

## Headers comunes en todas las requests

```
Content-Type: application/json
Content-Encoding: gzip          ← IMPORTANTE: el body va comprimido con gzip
Accept: */*
Accept-Encoding: gzip, deflate
User-Agent: <arriba>
Origin: https://music.youtube.com
Cookie: CONSENT=YES+1
X-Goog-Visitor-Id: <visitor_id>
```

## Endpoints consumidos

| Endpoint | Path | Quién lo llama | Tamaño típico | Notas |
| --- | --- | --- | --- | --- |
| `search` (unfiltered) | `POST /search` | `SearchResultScreenController._getInitSearchResult` | **~210 KB** ⚠️ | El bug actual. Devuelve TODAS las categorías de un golpe. |
| `search` (filtered) | `POST /search` con `params` | `onDestinationSelected` (al pulsar un tab o "view all") | ~30 KB | Mucho más liviano porque pide solo 1 categoría. |
| `search` (suggestions) | `POST /music/get_search_suggestions` | `getSearchSuggestion` (autocomplete) | < 5 KB | Por keystroke. |
| `browse` (home) | `POST /browse` con `browseId=FEmusic_home` | `getHome` | ~150 KB | 9 secciones mezcladas. |
| `browse` (artist) | `POST /browse` con `browseId=<channelId>` | `getArtist` | ~50 KB | |
| `browse` (album lookup) | `POST /browse` con `browseId=<audioPlaylistId>` | `getAlbumBrowseId` | < 5 KB | Solo resuelve el ID. |
| `next` (continuation) | `POST /next` con `continuation=<token>` | `getContinuations` (scroll infinito) | Variable | El token viene en la response anterior. |
| `player` | `POST /player` con `video_id=<id>` | `getSongWithId` | ~10 KB | Metadata de canción. |

## El problema de rendimiento: `search` unfiltered

**Síntoma:** la app carga 210 KB de JSON por cada búsqueda, aunque solo necesitemos ~10 items por categoría en la vista principal.

**Por qué pasa:**

`lib/services/music_service.dart:613`:
```dart
final response = (await _sendRequest("search", data)).data;
```

El método `search()` tiene un parámetro `int limit = 30`, pero **ese limit SOLO se usa para las continuaciones** (paginación), NO para la request inicial:

```dart
// Líneas 851 y 986 — limit solo afecta getContinuations:
final x = await getContinuations(
    res[shelfKey],
    'musicShelfContinuation',
    limit - ((searchResults[category] as List).length),  // ← acá
    ...
);
```

La request inicial (`_sendRequest("search", data)`) no acepta `count` ni `limit` en el body. YouTube Music devuelve TODO lo que considera relevante para el query (~10-20 items por shelf × 7-9 shelves = 100-200 items).

## El parámetro `params` (filter tokens)

YouTube Music usa tokens opacos en base64-like para filtrar por categoría. Estos tokens se construyen en `lib/services/utils.dart:getSearchParams()`:

| Filtro | Token `params` |
| --- | --- |
| (ninguno — unfiltered) | (sin `params`) |
| `songs` | `EgWKAQI` + `I` + `AWoMEA4QChADEAQQCRAF` |
| `videos` | `EgWKAQI` + `Q` + `AWoMEA4QChADEAQQCRAF` |
| `albums` | `EgWKAQI` + `Y` + `AWoMEA4QChADEAQQCRAF` |
| `artists` | `EgWKAQI` + `g` + `AWoMEA4QChADEAQQCRAF` |
| `playlists` | `Eg-KAQwIABAAGAAgACgB` + `MABqChAEEAMQCRAFEAo%3D` |
| `featured_playlists` | `EgeKAQQoA` + `Dg` + `BagwQDhAKEAMQBBAJEAU%3D` |
| `community_playlists` | `EgeKAQQoA` + `EA` + `BagwQDhAKEAMQBBAJEAU%3D` |

Cada token es ~3 segmentos concatenados. **No es un número, es un identificador opaco.** Lo más probable es que internamente sean datos protobuf codificados en base64 (formato típico de Google APIs).

## Hipótesis a investigar en Postman

### 1. ¿El filtro `params` afecta el tamaño de la response?

**Probar:** hacer una request unfiltered vs. una con `params=songs` y comparar tamaños. La hypothesis es que filtrado devuelve ~10 items, nofiltered devuelve ~200.

### 2. ¿Existe un parámetro `count` o `limit` en el body?

YouTube Music **podría** aceptar un campo `count` o `limit` en el body que límite items por shelf. Probar agregar al body:

```json
{
  "context": { ... },
  "query": "bruno mars",
  "count": 10
}
```

O probar agregar al `params` un sufijo (algunos tokens de Google codifican un conteo).

### 3. ¿Qué hay dentro de cada `musicShelfRenderer.contents`?

El usuario confirmó que la response unfiltered tiene `count=27` elementos en `sectionListRenderer.contents`. Cada uno puede ser:
- `musicCardShelfRenderer` (Top result — 1 item)
- `musicShelfRenderer` (lista — ~10-20 items)
- `itemSectionRenderer` (wrapper — contiene un `musicShelfRenderer` adentro)
- `musicCarouselShelfRenderer` (carrusel)

**Acción recomendada:** correr la request unfiltered en Postman con `?prettyPrint=true&alt=json` (sin `prettyPrint=false`) para ver la jerarquía completa con indentación nativa. Buscar si hay un campo `count`, `numResults`, o `maxResults` en algún shelf.

### 4. ¿El header `Range` o `Accept-Ranges` funciona?

YouTube Music no es un servidor HTTP típico, pero algunas APIs de Google aceptan `Range: items=0-9` para paginar. Probar agregar:
```
Range: items=0-9
```

## Endpoints alternativos / fallbacks

### Piped API (instancias comunitarias)
- `https://pipedapi.kavin.rocks/search?q=<query>&filter=music_songs`
- `https://pipedapi.kavin.rocks/streams/<videoId>`

Usado por `lib/services/piped_service.dart` cuando YouTube Music falla. **Ya filtrado por categoría** y mucho más liviano. Considerar migrar la búsqueda a Piped si el tamaño del response de YouTube Music es inmanejable.

## Recomendaciones inmediatas

1. **Mientras se depura el bug:** agregar un parámetro `?key=...&alt=json` (sin `prettyPrint=false`) en Postman para ver la jerarquía legible.

2. **Fix de corto plazo:** agregar un parámetro `count: 10` o similar al body de `search()` unfiltered, si YouTube Music lo respeta.

3. **Fix de medio plazo:** cambiar la vista principal para hacer **N requests filtradas en paralelo** (una por categoría: Songs, Videos, Albums, Artists, etc.) en vez de una sola unfiltered. Total: ~150 KB en 5 requests paralelas de ~30 KB cada una, pero podemos descartar lo que no nos interesa y cancelar las requests si el usuario ya interactuó con la vista.

4. **Fix de largo plazo:** migrar `search()` unfiltered a Piped API o implementar un proxy local que cachee y recorte las responses.

## Cómo usar la colección Postman

```bash
# 1. Abrir Postman → File → Import → seleccionar el .json
# 2. En la colección, abrir la pestaña "Variables" y pegar tu X-Goog-Visitor-Id
#    (lo puedes ver con `flutter logs | grep "Visitor id"`)
# 3. Probar primero "search - unfiltered (MAIN VIEW BUG)" con query="bruno mars"
# 4. Comparar tamaño con "search - filtered (songs)" con mismo query
# 5. Experimentar con agregar "count": 10 al body
```
