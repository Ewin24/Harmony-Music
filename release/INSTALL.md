# Installation Guide — Harmony-Music v1.12.2

> **Versión:** 1.12.2 · **Fecha:** 2026-06-25

## ¿Qué archivo descargo?

| Tu dispositivo | Archivo | Razón |
| --- | --- | --- |
| **Cualquier Android moderno** (2018+) | `Harmony-Music-v1.12.2-universal-release.apk` (69 MB) | Funciona en todos, archivo único |
| **Solo teléfonos arm64** (mayoría desde 2018) | `Harmony-Music-v1.12.2-arm64-v8a.apk` (25 MB) | Mucho más liviano, 3x menor |
| **Solo armv7** (teléfonos viejos, pre-2018) | `Harmony-Music-v1.12.2-armeabi-v7a.apk` (23 MB) | Para hardware legacy |
| **Solo emulador x86_64 o Chromebook** | `Harmony-Music-v1.12.2-x86_64.apk` (26 MB) | Para testing en desktop virtual |
| **Google Play Store** | `Harmony-Music-v1.12.2-release.aab` (65 MB) | Solo si vas a publicar oficialmente |

**Si no sabes cuál elegir:** descarga el **universal APK** (69 MB). Es más grande pero funciona en todos lados.

## Instalación paso a paso

### En el celular (Android 8.0+)

**Método 1: Directamente desde el celular**

1. Descarga el archivo `.apk` desde GitHub Releases a tu celular (Chrome lo descarga a la carpeta `Downloads/`).
2. Abre el archivo desde la notificación o desde el administrador de archivos.
3. Si Android pregunta "Permitir instalar apps de esta fuente", habilita el permiso para Chrome o tu navegador.
4. Toca **Instalar**.
5. Espera 5-10 segundos a que se instale.
6. Abre **Harmony Music** desde el launcher.

**Método 2: Desde la PC con ADB**

```bash
# 1. Conecta el celular por USB con "Depuración USB" habilitada en Opciones de Desarrollador
adb devices
# Debe listar tu dispositivo

# 2. Instala
adb install release/Harmony-Music-v1.12.2-arm64-v8a.apk
# (sustituye por el archivo que corresponda a tu dispositivo)

# 3. Lanza
adb shell am start -n com.anandnet.harmonymusic/.MainActivity
```

**Método 3: Google Play Store (oficial)**

Solo aplica si publicaste el `.aab` en Google Play Console. Los usuarios lo instalan como cualquier otra app desde la Play Store.

## Verificar la instalación

Después de instalar, abre la app. Deberías ver:

- **Home** con secciones (Quick picks, Mixes, etc.)
- **Search** (ícono de lupa en la barra inferior o en el menú lateral) — escribe un artista y verifica que aparezcan las previews

Si algo no carga:
- **Verifica tu internet** — la app necesita hacer requests a `music.youtube.com`
- **Limpia cache**: `Settings → Apps → Harmony Music → Storage → Clear cache`
- **Reporta un bug**: https://github.com/Ewin24/Harmony-Music/issues — incluye `flutter logs` si puedes

## Verificación de integridad (opcional pero recomendado)

```bash
# Linux / macOS
cd release
sha256sum -c SHA256SUMS.txt
# Debe decir "OK" para todos los archivos

# Windows (PowerShell)
cd release
Get-FileHash -Algorithm SHA256 -Path *.apk, *.aab
# Compara con los hashes de SHA256SUMS.txt
```

## Requisitos del sistema

| Componente | Mínimo | Recomendado |
| --- | --- | --- |
| Android | 5.0 (Lollipop, API 21) | 10.0+ (Q, API 29) |
| RAM | 2 GB | 4 GB+ |
| Almacenamiento | 200 MB libres | 500 MB libres |
| Internet | Requerido para streaming | Wi-Fi para audio de alta calidad |
| Permisos | Almacenamiento, Internet | Notificaciones (opcional) |

## Permisos que pide la app

- **Internet** — para streaming
- **Almacenamiento** — para descargar canciones (opcional)
- **Notificaciones** — para el player de audio en background
- **Foreground Service** — para reproducción continua cuando la app está en background

La app **NO** pide:
- Cámara
- Micrófono
- Ubicación
- Contactos
- SMS

## Troubleshooting

### "App not installed" / "Package conflicts with existing package"

Probablemente tienes una versión anterior con una firma diferente. Desinstala primero:

```bash
adb uninstall com.anandnet.harmonymusic
adb install release/Harmony-Music-v1.12.2-arm64-v8a.apk
```

### "Parse error: There was a problem parsing the package"

El archivo se descargó corrupto. Vuelve a descargarlo y verifica el hash SHA256.

### La app abre pero no carga contenido / da error de red

- YouTube Music puede haber bloqueado la IP/región. La app usa la API interna no oficial y Google puede rate-limitar o bloquear.
- Solución alternativa: configurar la app para usar un proxy o VPN.

### La búsqueda no muestra artistas/álbumes en la vista principal

Si este bug regresa, activa el recorder para capturar el response exacto:
```bash
flutter run --dart-define=RECORD_API=true
# busca algo
adb pull /sdcard/Android/data/com.anandnet.harmonymusic/files/api_recordings/
# y abre un issue con los .txt resultantes
```

## Desinstalación

Igual que cualquier app Android: `Settings → Apps → Harmony Music → Uninstall`.

El recorder a disco se borra automáticamente (Android limpia el external app dir al desinstalar).

---

Para más información ver `RELEASE-NOTES.md` y `docs/api/` en el repositorio.
