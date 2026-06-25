# Alternativas a la API interna de YouTube Music

> **Generado el 2026-06-23** después de confirmar que la API interna (InnerTube) de YouTube Music no tiene documentación oficial y rompe silenciosamente cada vez que Google cambia algo.

## Estado actual

La app usa la **API interna no oficial** de YouTube Music (InnerTube / `youtubei/v1/`), reverse-engineered por la comunidad. Esto implica:

- **Cero garantías de estabilidad.** YouTube Music puede cambiar el shape de cualquier response sin avisar. Ya lo hizo una vez durante este debug (envolvió los shelves en `itemSectionRenderer`) y rompió la búsqueda.
- **Sin rate limit documentado.** Si lo excedes, tu IP puede quedar throttled o baneada.
- **Términos de servicio grises.** YouTube no aprueba explícitamente el uso no oficial; técnicamente está en un área legal ambigua.
- **Sin soporte.** Si Google decide bloquear clientes no-oficiales (como hizo con muchas apps de YouTube en el pasado), el proyecto queda muerto.

## Opciones evaluadas

### 1. Qobuz, Tidal, Deezer, Spotify, Apple Music — APIs oficiales

**Ventajas:**
- Documentación completa y estable.
- SDKs oficiales en prácticamente todos los lenguajes.
- Catálogo masivo y legal.
- OAuth estándar, sin romper nunca.

**Desventajas:**
- **Requieren cuenta de usuario y OAuth.** La app actual funciona anónimamente.
- **Pricing para acceso completo.** Las APIs gratuitas de Spotify/Web Playback SDK no dan audio de alta calidad; Apple y Tidal cobran por el tier que da acceso a la API completa.
- **Reescritura del 100% del cliente.** No es un parche; es un proyecto nuevo.
- **Región.** Algunos servicios no están disponibles en todos los países.

**Cuándo elegirlo:** si la app va a producción real, dirigida a usuarios finales, o si quieres monetizar.

### 2. Spotify Web Playback SDK (gratis, con cuenta)

**Ventajas:**
- API oficial, estable, bien documentada.
- Plan gratuito soporta la API.
- 30-second previews gratis; full streaming con Premium.

**Desventajas:**
- Requiere app de Spotify abierta en el mismo dispositivo para full streaming.
- Full playback solo con Spotify Premium.
- Reescritura total.

**Cuándo elegirlo:** si tus usuarios ya tienen Spotify.

### 3. Piped / Invidious — proxy comunitario de YouTube

**Ventajas:**
- API REST simple y pública (`pipedapi.kavin.rocks/search?q=...`).
- Ya hay cliente Dart parcial en `lib/services/piped_service.dart`.
- Devuelve streams directos (no DRM).
- No requiere autenticación para la mayoría de endpoints.

**Desventajas:**
- Depende de instancias comunitarias (pueden caer, throttlear, o cambiar de URL).
- Streams son yt-dlp-style: cambia YouTube el formato y se rompe.
- Catálogo: 100% YouTube (lo que ya tenés).
- Sin metadata "oficial" de YT Music (mood, mixtapes, lyrics oficiales).

**Cuándo elegirlo:** si querés mantener la "magia" de YT Music (todo su catálogo gratis) pero con un transporte más limpio.

### 4. NewPipe extractor (Java/Kotlin, portado a Dart por `newpipeextractor_dart`)

**Ventajas:**
- Mantenido activamente por la comunidad NewPipe.
- Diseño pensado para extraer metadata de YouTube sin usar la API interna.

**Desventajas:**
- También rompe cuando YouTube cambia las cosas (mismo problema que estamos teniendo).
- Sin cliente HTTP oficial; tenés que escribirlo.
- Mantenimiento pesado.

**Cuándo elegirlo:** si querés escribir tu propio cliente YouTube sin pasar por `youtubei/v1/`.

### 5. inner-tune / ytmusicapi (Python) — portar a Dart

**Ventajas:**
- Librería Python muy madura y bien probada (`ytmusicapi` por `sigma67`).
- Hay un puerto parcial a Dart (`inner-tune`) pero está incompleto.

**Desventajas:**
- Sigue siendo no oficial → sigue rompiendo.
- El puerto Dart está verde.

**Cuándo elegirlo:** solo si el bug que estamos persiguiendo es crítico y querés usar código probado en otro lenguaje como referencia.

### 6. Mejorar lo que tenemos (recomendado corto plazo)

**Ventajas:**
- Sin reescritura.
- El recorder de respuestas que acabamos de agregar nos da el material para hacer ingeniería inversa con datos reales.

**Desventajas:**
- Sigue dependiendo de la API no oficial.
- Hay que invertir tiempo en robustecer el parser.

**Cuándo elegirlo:** si querés sacar una versión funcional rápido y tenés energía para cazar bugs cuando YT Music cambie.

### 7. Spotify Free con `librespot` o `spotify-dart`

**Ventajas:**
- Acceso a millones de canciones sin Premium.
- `librespot` es el cliente open-source no-oficial usado por Spotify Connect.
- Catálogo completo de Spotify.

**Desventajas:**
- **Cuentas de Spotify Free tienen restricciones de audio quality** y 30-second previews en mobile.
- Para full streaming free, hay que usar cuentas "viejas" o servicios similares.
- Riesgo legal real (Spotify ha demandado a proyectos similares).

**Cuándo elegirlo:** no lo recomendaría por temas legales.

## Recomendación práctica

| Si tu objetivo es... | Entonces... |
| --- | --- |
| **Hacer un portafolio / demo** que muestre skills técnicas | Quédate con la API actual + recorder. Es la ruta más rápida y la que ya tienes. |
| **Lanzar a usuarios reales en LATAM** | Migra a **Spotify Web Playback SDK** o **Deezer API**. Las dos tienen tier gratuito decente y documentación oficial. |
| **Mantener 100% del catálogo de YT Music sin cuenta** | Mejora el recorder → encuentra el bug → robustece. Acepta que es un proyecto frágil. |
| **Empezar de cero con algo serio** | **Spotify Web Playback SDK** + tu UI actual. Reusa 80% del código Flutter, solo cambias `lib/services/music_service.dart` por un `SpotifyService`. |

## Próximos pasos concretos (si seguimos con YT Music)

1. **Correr la app con el recorder activo** durante 1 hora con varias queries.
2. **Abrir los .txt resultantes** y comparar:
   - ¿Hay un campo `count` o `numItems` configurable?
   - ¿El `params` token cambia entre queries?
   - ¿La shape de los 27 elementos varía según el query?
3. **Si hay un campo limit:** arreglar `_sendRequest` para enviarlo. Cierra el bug de performance en 5 minutos.
4. **Si no hay campo limit:** evaluar el approach de "N requests filtradas en paralelo" mencionado en `API-SURFACE.md`.
5. **Si nada funciona:** evaluar Piped como reemplazo completo (es 1 semana de trabajo, no 1 mes).

## Si decides migrar a Spotify o Deezer

Avísame y abrimos un ciclo SDD nuevo para eso. Los pasos serían:
1. Spec: definir qué features de la app actual queremos mantener (search, playlists, library, downloads).
2. Evaluar cobertura de la API objetivo (Deezer tiene search + library + playlists gratis, Spotify requiere OAuth y Premium para algunas cosas).
3. Implementar `SpotifyService` / `DeezerService` paralelo a `MusicServices`.
4. Feature flag para alternar entre backends.
5. Eventualmente deprecar `MusicServices`.

No es trivial pero es el camino correcto si querés una app que sobreviva más de 6 meses sin que Google rompa algo.
