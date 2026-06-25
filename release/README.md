# Release v1.12.2 — Harmony-Music

Esta carpeta contiene todo lo necesario para distribuir e instalar Harmony-Music v1.12.2.

## 📦 Contenido

| Archivo | Tamaño | Para qué sirve |
| --- | --- | --- |
| `Harmony-Music-v1.12.2-universal-release.apk` | 69 MB | Instalación directa en cualquier Android moderno |
| `Harmony-Music-v1.12.2-arm64-v8a.apk` | 25 MB | Solo dispositivos arm64 (mayoría desde 2018) |
| `Harmony-Music-v1.12.2-armeabi-v7a.apk` | 23 MB | Solo dispositivos armv7 (teléfonos viejos) |
| `Harmony-Music-v1.12.2-x86_64.apk` | 26 MB | Solo emuladores x86_64 y Chromebooks |
| `Harmony-Music-v1.12.2-release.aab` | 65 MB | Google Play Store (genera APKs optimizados automáticamente) |
| `RELEASE-NOTES.md` | - | Changelog detallado, bugs arreglados, commits |
| `INSTALL.md` | - | Instrucciones de instalación, troubleshooting |
| `install.sh` | - | Script bash para Linux/macOS/WSL/Git Bash |
| `install.bat` | - | Script batch para Windows CMD |
| `SHA256SUMS.txt` | < 1 KB | Hashes para verificar integridad |

## 🚀 Instalación rápida

### Opción 1: Desde el celular (más fácil)

1. Descarga `Harmony-Music-v1.12.2-universal-release.apk` desde esta página de release a tu celular.
2. Abre el archivo desde la notificación o el administrador de archivos.
3. Toca **Instalar**.
4. Abre **Harmony Music** desde el launcher.

### Opción 2: Por ADB (más rápido para developers)

```bash
# Linux / macOS / WSL / Git Bash
./install.sh

# Windows CMD
install.bat
```

El script detecta automáticamente la ABI de tu dispositivo e instala el APK correcto.

### Opción 3: Manualmente por ADB

```bash
adb install -r Harmony-Music-v1.12.2-arm64-v8a.apk
```

## ✅ Verificar integridad

```bash
# Linux / macOS
sha256sum -c SHA256SUMS.txt

# Windows PowerShell
Get-FileHash -Algorithm SHA256 -Path *.apk, *.aab
```

## 📋 Para crear la release en GitHub

1. Ve a https://github.com/Ewin24/Harmony-Music/releases/new
2. **Tag:** `v1.12.2`
3. **Title:** `v1.12.2 — Search results preview + debug recorder`
4. **Description:** (copia el contenido de `RELEASE-NOTES.md` o usa la versión corta de abajo)
5. Arrastra todos los archivos de esta carpeta (excepto `install.sh`, `install.bat`, `SHA256SUMS.txt`) al área de attachments
6. Click **Publish release**

### Descripción corta (para pegar en GitHub)

```markdown
## v1.12.2 — Search results preview + debug recorder

**Bugfix crítico:** la búsqueda en la vista principal ahora muestra previews reales (artistas, canciones, álbumes) en vez de secciones vacías con "view all".

**Cambios principales:**
- ✅ Bucketing reescrito para el nuevo shape de la respuesta de YouTube Music (flat items, no shelves)
- ✅ `parseSearchResult` ahora prioriza `pageType` sobre `flexColumns[1]`
- ✅ Secciones vacías de "Community playlists" eliminadas
- ✅ Crash `type 'Album' is not a subtype of type 'Playlist?'` arreglado
- ✅ Nuevo `ResponseRecorder` para debugging: graba requests/responses a disco
- ✅ HTTP logger compacto (sin dumps de 200KB en consola)

**Descargas:**
- Universal APK (69 MB) — cualquier Android moderno
- arm64-v8a (25 MB) — la mayoría de teléfonos
- armeabi-v7a (23 MB) — teléfonos viejos
- x86_64 (26 MB) — emuladores
- AAB (65 MB) — Google Play Store

Ver `RELEASE-NOTES.md` y `INSTALL.md` para más detalles.
```

## 🐛 Reportar problemas

https://github.com/Ewin24/Harmony-Music/issues

Por favor incluye:
- Modelo del dispositivo y versión de Android
- Pasos para reproducir el bug
- Salida de `adb logcat | grep -i harmony` si es un crash
- Si es un bug de búsqueda, incluye los recordings (ver `../docs/api/RECORDER.md`)
