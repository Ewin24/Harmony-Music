# Tasks: Migrate Plugins to Built-in Kotlin

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~15-30 |
| 400-line budget risk | Very Low |
| Chained PRs recommended | No |
| Suggested split | Single PR (2 commits) |
| Delivery strategy | ask-always |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | App-side KGP removal + Kotlin DSL migration | Commit 1 | Base: main; no test changes |
| 2 | Plugin version bumps for built-in Kotlin compat | Commit 2 | Depends on commit 1 verifying clean build first |

## 1. ✅ App-side cleanup: remove KGP from `android/app/build.gradle` and `android/gradle.properties`

- [x] Remove `id "kotlin-android"` from `android/app/build.gradle` plugins block
- [x] Replace `kotlinOptions { jvmTarget = '17' }` with `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }` and add import
- [x] Remove `android.builtInKotlin=false` and `android.newDsl=false` from `android/gradle.properties`
- ✅ All grep checks pass (0 matches for all patterns)
- ✅ `flutter clean && flutter build apk --debug` succeeds
- **Commit**: `dbd677e` — `build: enable Flutter built-in Kotlin and migrate app to new Kotlin DSL`

## 2. ✅ Partially completed: Plugin upgrades in `pubspec.yaml`

- [x] ~~audiotags: ^1.4.1 → ^1.4.5~~ **REVERTED** — needs `flutter_rust_bridge 2.7.0` conflicting with `smtc_windows ^0.1.2`
- [x] ~~package_info_plus: ^8.0.0 → ^10.1.0~~ **REVERTED** — needs `win32 ^6.0.1` conflicting with `share_plus ^10.1.4`
- [x] ~~share_plus: ^10.1.4 → ^13.1.0~~ **REVERTED** — needs `win32 ^6.0.1` conflicting with `file_picker ^8.0.6`
- [x] ~~wakelock_plus: ^1.3.3 → ^1.6.1~~ **REVERTED** — depends on `package_info_plus ^10.1.0`
- [x] Switch `terminate_restart` from git fork to `^1.1.0` (pub) — **SUCCESS**
- [x] `flutter clean && flutter pub get` — resolved successfully
- ✅ `flutter build apk --debug` succeeds
- **Commit**: `0ba0956` — `build: upgrade plugins to versions compatible with built-in Kotlin`
- **Deviation**: Only `terminate_restart` could be upgraded. The other 4 plugins had transitive dependency conflicts that blocked upgrading. All reverted to original versions.

## 3. ✅ Partial: Final verification

- [x] ~~`flutter analyze` — 0 errors, 0 warnings~~ → **1 pre-existing warning** (`experimental_member_use` on `LockCachingAudioSource` in `audio_handler.dart` — not caused by this change)
- [x] `flutter build apk --debug` — exit code 0, APK at `build/app/outputs/flutter-apk/app-debug.apk` (161MB)
- [x] Grep `id "kotlin-android"` in `app/build.gradle` — 0 matches
- [x] Grep `android.builtInKotlin` in `gradle.properties` — 0 matches

> **Note**: Plugin-level KGP warnings in build output are expected (upstream limitation — none of the 5 plugins have removed manual KGP yet). Only the *app module* KGP application is a blocker.
