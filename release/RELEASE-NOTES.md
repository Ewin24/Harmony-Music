# Release Notes — Harmony-Music v1.12.2

> **Fecha:** 2026-06-25 · **Tipo:** Bugfix release · **Basada en:** `Edwin-DEV` @ `e926175`

## TL;DR

La búsqueda en la vista principal de la app ahora muestra previews reales (artistas, álbumes, canciones, etc.) en vez de secciones vacías con "view all". También se añadieron herramientas de debugging (logger estructurado + recorder a disco) y se documentó la API interna que consume la app.

## Cambios visibles para el usuario

| Antes | Ahora |
| --- | --- |
| Buscar un artista → "no aparece nada" en `results` | Buscar un artista → previews de artistas, canciones, álbumes, etc. en `results` |
| Sección "Community playlists" vacía con altura 200px sin nada | Sección eliminada (accesible vía el tab del rail) |
| Crash `type 'Album' is not a subtype of type 'Playlist?'` al buscar community playlists | Sin crash; clasificado correctamente como Playlist |
| Cuando YouTube Music cambiaba el shape de la respuesta, no había forma de debuggearlo | `--dart-define=RECORD_API=true` graba todas las requests a disco para análisis offline |

## Cambios para developers

- **Nuevo `ResponseRecorder`**: persiste cada request/response HTTP a `<app docs>/api_recordings/<session>/` con headers + body pretty-printed. Accesible vía `adb pull` sin `run-as` y sin frenar la app.
- **HTTP logger compacto**: metadatos (status, time, size, top-level keys) en consola. Bodies completos van a disco, no a la consola.
- **Postman collection** en `docs/api/`: 8 endpoints pre-rellenados con headers y `params` tokens.
- **Análisis de la API**: `docs/api/API-SURFACE.md` mapea todos los endpoints consumidos, `docs/api/ALTERNATIVES.md` evalúa 7 caminos si se quiere migrar a otra plataforma.

## Cambios técnicos

| Commit | Descripción |
| --- | --- |
| `e9486b8` | `feat(debug): add ResponseRecorder utility for capturing raw API responses to disk` |
| `6f68f86` | `feat(debug): integrate ResponseRecorder into HTTP interceptor and bootstrap` |
| `f10a3cf` | `fix(nav_parser): use pageType as canonical type signal in parseSearchResult` |
| `1606853` | `fix(search): rewrite bucketing for new flat-items response shape` |
| `cd520a2` | `fix(widget): skip buckets with wrong item type or empty content` |
| `2c020d5` | `docs(api): add Postman collection, API surface map, recorder guide, and alternatives analysis` |
| `e926175` | `chore(openspec): archive completed change sets and sync delta specs` |

## Bug crítico que se arregló

YouTube Music dejó de devolver los resultados de búsqueda agrupados en "shelves" con título (Songs / Artists / Albums / etc.) y ahora devuelve una **lista plana** de items individuales envueltos en `itemSectionRenderer.contents[0].musicResponsiveListItemRenderer`. La categorización se hace client-side usando `navigationEndpoint.browseEndpoint.browseEndpointContextMusicConfig.pageType`.

El código anterior buscaba "shelf titles" que ya no existían → 24 de 25 items caían en `_orphan_*` → la vista principal renderizaba secciones vacías o con "view all" pero sin contenido.

**Solución:** bucketing completamente reescrito para clasificar cada item por su `pageType` en vez de por shelf title. Ver `docs/api/API-SURFACE.md` para el detalle.

## Limitaciones conocidas

- La API interna de YouTube Music NO es oficial y NO tiene garantía de estabilidad. Google puede romperla sin aviso. Esto fue lo que pasó durante el desarrollo de este release.
- 200KB+ por search unfiltered. No hay forma conocida de pedir menos items (ver `docs/api/API-SURFACE.md` para los intentos de optimización).
- El recorder a disco está limitado a 200 archivos por sesión (auto-rotation).
- No hay tests automatizados para el parser. La regresión más probable es un cambio de shape en YouTube Music.

## Verificación

- ✅ `flutter analyze` pasa con 0 errores
- ✅ Build de release exitoso en los 4 formatos (universal APK, split APKs por ABI, AAB)
- ✅ Probado en dispositivo físico (Android) — previews de artistas, canciones, etc. se muestran correctamente
- ✅ Recorder escribe archivos a `/sdcard/Android/data/com.anandnet.harmonymusic/files/api_recordings/`

## Próximos pasos sugeridos

- [ ] Agregar widget tests para `parseSearchResult` y `classifySearchResultBucket`
- [ ] Considerar migrar a Spotify Web Playback SDK o Deezer API (ver `docs/api/ALTERNATIVES.md`)
- [ ] Hacer que el recorder esté toggleable desde la pantalla de Settings
- [ ] Reducir el tamaño del APK universal (68.7 MB) — considerar Dynamic Features o AAB-only

## Agradecimientos

Gracias a:
- La comunidad de `ytmusicapi` (Python) cuyo trabajo previo hizo posible entender la API
- Los usuarios que reportaron el bug con logs de `flutter logs`

---

**Archivos adjuntos en este release:**

| Archivo | Tamaño | Para qué sirve |
| --- | --- | --- |
| `Harmony-Music-v1.12.2-universal-release.apk` | 69 MB | Instalación directa en cualquier Android moderno (arm64 + armv7 + x86_64) |
| `Harmony-Music-v1.12.2-arm64-v8a.apk` | 25 MB | Solo dispositivos arm64 (la mayoría de teléfonos desde 2018) |
| `Harmony-Music-v1.12.2-armeabi-v7a.apk` | 23 MB | Solo dispositivos armv7 (teléfonos viejos) |
| `Harmony-Music-v1.12.2-x86_64.apk` | 26 MB | Solo emuladores x86_64 y Chromebooks |
| `Harmony-Music-v1.12.2-release.aab` | 65 MB | Google Play Store (genera APKs optimizados por dispositivo automáticamente) |
| `SHA256SUMS.txt` | < 1 KB | Verificación de integridad |
| `INSTALL.md` | < 10 KB | Instrucciones de instalación y troubleshooting |
