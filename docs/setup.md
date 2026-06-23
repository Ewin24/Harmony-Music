# Harmony-Music Developer Setup Guide

Set up a complete build environment for Harmony-Music on Windows 11. Follow these
steps in order — each section is safe to re-run if something fails.

> **Prerequisites**  
> - Windows 11 (64-bit)  
> - ~5 GB free disk space (Flutter SDK ~1.5 GB, Android SDK ~2 GB, JDK ~0.5 GB)  
> - Git for Windows ([git-scm.com](https://git-scm.com))  
> - Administrator access (for symlink/Developer Mode permissions)  
> - A stable internet connection

---

## 1. Install Flutter SDK

Harmony-Music was verified with **Flutter 3.44.2 stable**. Older 3.24.x versions
may work but are not tested.

1. Download the SDK archive:  
   `https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.2-stable.zip`

2. Extract the ZIP to a short path with no spaces, for example:  
   `D:\flutter\flutter`

3. Add Flutter's `bin` directory to your **User PATH** environment variable:  
   `D:\flutter\flutter\bin`

4. Verify the installation in a **new** terminal:
   ```batch
   flutter --version
   ```
   Expected output:
   ```
   Flutter 3.44.2 • channel stable • https://github.com/flutter/flutter.git
   Framework • revision c9a6c48423
   Tools • Dart 3.12.2 • DevTools 2.57.0
   ```

> **Tip**: Use a short path like `D:\flutter\flutter` to avoid Windows MAX_PATH
> issues. Flutter includes Dart automatically — no separate Dart install needed.

---

## 2. Install Java JDK

The Android build requires **JDK 17 or later** (JDK 21 LTS recommended).

- **Option A (recommended)**: Install Eclipse Temurin JDK 21 from  
  [adoptium.net](https://adoptium.net/temurin/releases/?version=21)

- **Option B**: Use the JDK bundled with Android Studio (if installed)

After installation:

1. Set `JAVA_HOME` to your JDK root (e.g., `C:\Program Files\Eclipse Adoptium\jdk-21.0.6-hotspot`)
2. Add `%JAVA_HOME%\bin` to your `PATH`
3. Verify:
   ```batch
   java --version
   ```
   Expected: `openjdk 21.x` or `17.x`

> The Android Gradle Plugin 8.6+ requires Java 17 as minimum. JDK 21 is fully
> compatible and recommended for future-proofing.

---

## 3. Install Android SDK (Command-Line Tools)

You do **not** need the full Android Studio GUI — command-line tools are
sufficient for building.

1. Download the command-line tools from the Android developer site:  
   `https://developer.android.com/studio#command-line-tools-only`

2. Extract to your SDK root, e.g. `D:\Android\Sdk\cmdline-tools\latest`

3. Set the `ANDROID_HOME` environment variable:  
   `D:\Android\Sdk`

4. Install the required SDK components:
   ```batch
   sdkmanager "platforms;android-35" "build-tools;35.0.0"
   ```

5. Accept the Android licenses:
   ```batch
   flutter doctor --android-licenses
   ```

6. Verify everything is recognized:
   ```batch
   flutter doctor
   ```
   Expected: all Android toolchain items show `[✓]`, no blocking `[X]` issues.

> **Alternative**: Install Android Studio (full IDE, ~2 GB). It bundles the SDK
> manager, emulator, and JDK. If you prefer this route, the SDK root will be at
> `%LOCALAPPDATA%\Android\Sdk` by default.

---

## 4. Clone and Configure the Repository

```batch
git clone https://github.com/anandnet/Harmony-Music.git
cd Harmony-Music
```

### About the `.flutter` Submodule

The repository contains a `.flutter` submodule pointing to the Flutter GitHub
repo. This submodule is **optional** — the recommended approach is to use the
system-wide Flutter SDK on your `PATH`.

If you prefer to use the submodule:

```batch
git submodule update --init
```

If the submodule fails (slow download or network issues), delete `.flutter/` and
rely on the system Flutter SDK instead. Both approaches work.

---

## 5. Resolve Dependencies

```batch
flutter pub get
```

This fetches all dependencies — both from `pub.dev` and from the four custom
GitHub forks:

| Package | Fork Ref |
|---------|----------|
| `youtube_explode_dart` | `1d9ec9baa806705b1d859260eeb389ec28c6b024` |
| `just_audio_media_kit` | `6672eb82657d9e671abbf42122031c88aa9e6d80` |
| `sidebar_with_animation` | `b53567a42b4ba3793a3cf00d478bdba0ecce33d7` |
| `terminate_restart` | `eb505e07e11d0fe1f5c03993e707c6678428c353` |

Expected output: `Process finished with exit code 0` and no resolution errors.

---

## 6. Verify Static Analysis

```batch
flutter analyze
```

Expected: `No issues found!` and exit code 0.

Some pre-existing **warnings and infos** may appear for legacy code — these are
non-blocking. The important target is **zero errors**.

---

## 7. Build the Debug APK

```batch
flutter build apk --debug
```

Expected output:
- Exit code 0
- APK artifact at `build/app/outputs/flutter-apk/app-debug.apk`

First build may take several minutes (Gradle daemon warm-up, NDK extraction for
native dependencies). Subsequent builds are faster.

---

## Build Environment Reference

| Component | Version / Path |
|-----------|---------------|
| Flutter SDK | `D:\flutter\flutter` (3.44.2 stable) |
| Dart SDK | Bundled with Flutter (`bin\cache\dart-sdk`) |
| Java JDK | 21 LTS (Eclipse Temurin), `JAVA_HOME` set |
| Android SDK | `D:\Android\Sdk` |
| Android platform | `android-35` |
| Build tools | `35.0.0` |
| NDK | 26.1.10909125 (auto-installed by sdkmanager) |

---

## Troubleshooting

### NDK corrupt download

If the build fails with NDK-related errors:
```batch
sdkmanager --uninstall ndk
sdkmanager "ndk;26.1.10909125"
```

### Build-tools 34 missing

Flutter 3.44.2 may expect `build-tools;34.0.0` alongside `35.0.0`. Install both:
```batch
sdkmanager "build-tools;34.0.0" "build-tools;35.0.0"
```

### Symlink / Developer Mode

Flutter's `flutter pub get` creates symlinks in `.dart_tool/`. On Windows, this
requires either:
- **Developer Mode** enabled (Settings → Privacy & Security → For Developers), or
- Running your terminal **as Administrator**

If you see "Error: Cannot create symbolic link", enable Developer Mode or
re-run the terminal as Administrator.

### `DialogTheme` / `IconData final` (Dart 3.12 breakages)

Dart 3.12 made `IconData` constructors `final`, and Flutter 3.4x renamed
`DialogTheme` to `DialogThemeData`. If your local SDK is older, you may see
compilation errors like:
- `The named parameter 'icon' isn't defined` — replace `Ionicons.xxx` with
  equivalent `Icons.xxx` from Material
- `DialogTheme` not found — rename to `DialogThemeData`

The codebase has already been migrated for Flutter 3.44.2 + Dart 3.12. If you
are on a different version, apply similar changes.

### `ionicons` Package Abandoned

The `ionicons` package (`^0.2.2`) was removed from `pubspec.yaml` because it is
abandoned and incompatible with Dart 3.12's `final` class constraint. All
references have been replaced with equivalent Material `Icons` constants.

If you encounter missing icon references, check you are on the latest commit
that includes this migration.

### License Acceptance

If `flutter doctor` shows unaccepted licenses for Android:
```batch
flutter doctor --android-licenses
```
Type `y` for each license prompt.

### Windows Desktop Builds

Building the Windows target (`flutter build windows`) requires **Visual Studio
Build Tools** with the "Desktop development with C++" workload (~6 GB). This is
**out of scope** for the primary APK build and only needed if you modify the
Windows desktop app.

### Antivirus Interference

Some antivirus software flags Dart/Flutter processes. If `flutter` commands hang
or crash, add the Flutter SDK directory to your antivirus exclusion list.

### Long Paths

If `git clone` fails with path-length errors:
```batch
git config --global core.longpaths true
```

---

## Quick Reference (copy-paste)

```batch
# Step 1: Verify Flutter SDK
flutter --version

# Step 2: Verify JDK
java --version

# Step 3: Verify Android SDK
flutter doctor

# Step 4: Get dependencies
flutter pub get

# Step 5: Analyze
flutter analyze

# Step 6: Build APK
flutter build apk --debug
```

After completing all steps, the file `build/app/outputs/flutter-apk/app-debug.apk`
should exist and be ready for installation.
