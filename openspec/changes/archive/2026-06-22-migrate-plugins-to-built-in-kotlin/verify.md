# Verification Report: migrate-plugins-to-built-in-kotlin

**Date**: 2026-06-22
**Verdict**: PASS_WITH_FOLLOWUPS

---

## Executive Summary

The app-side migration is complete and correct in commits (`dbd677e`, `0ba0956`): `android/app/build.gradle` no longer applies KGP manually, uses the new Kotlin DSL with `JvmTarget.JVM_17`, and the APK builds successfully. However, the working tree of `android/gradle.properties` has regressed — `android.builtInKotlin=false` and `android.newDsl=false` were re-added after the commit (uncommitted changes). Additionally, only 1 of 5 plugins (`terminate_restart`) was upgraded due to transitive dependency conflicts, and plugin-level KGP warnings persist in build output (upstream limitation). Fix the `gradle.properties` regression, then archive.

---

## Scenario Results

| # | Description | Status | Evidence |
|---|-------------|--------|----------|
| R1 | App `build.gradle` does not apply KGP manually | ✅ PASS | `grep` for `kotlin-android` in `android/app/build.gradle` returns 0 matches |
| R2 | App uses new Kotlin DSL with JvmTarget.JVM_17 | ✅ PASS | `kotlinOptions` returns 0 matches; `compilerOptions` + `JvmTarget` found at lines 1, 37, 38 |
| R3 | `android/gradle.properties` has no builtInKotlin opt-out | ❌ FAIL | Working tree has `android.builtInKotlin=false` (line 9) and `android.newDsl=false` (line 11) — regressed from committed state |
| R4 | All 5 plugins upgraded to built-in-Kotlin-compatible versions | ❌ FAIL (partial) | Only `terminate_restart: ^1.1.0` upgraded. Others reverted: `audiotags ^1.4.1`, `package_info_plus ^8.0.0`, `share_plus ^10.1.4`, `wakelock_plus ^1.3.3` — blocked by transitive dep conflicts |
| R5 | `flutter build apk --debug` succeeds | ✅ PASS | Exit code 0. APK at `build/app/outputs/flutter-apk/app-debug.apk` (168MB) |
| R6 | `flutter analyze` is clean | ⚠️ WARNING | 1 warning: `experimental_member_use` on `LockCachingAudioSource` (pre-existing, not caused by this change) |
| R7 | Build output has no KGP warnings | ❌ FAIL | Build output warns: "Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): audiotags, package_info_plus, share_plus, terminate_restart, wakelock_plus" — known upstream limitation |

---

## Findings

### CRITICAL (blocks archive)

1. **R3: `android/gradle.properties` working tree regression**
   - **Area**: `android/gradle.properties`
   - **Description**: The commit `dbd677e` correctly removed `android.builtInKotlin=false` and `android.newDsl=false`. The working tree has uncommitted changes that re-added these lines (lines 9 and 11). Must be restored before archive.
   - **Recommendation**: Run `git checkout -- android/gradle.properties` to restore committed state, or manually delete the two flag lines.

### WARNING (should address, doesn't block archive)

2. **R4: Plugin upgrades incomplete**
   - **Area**: `pubspec.yaml` — audiotags, package_info_plus, share_plus, wakelock_plus
   - **Description**: 4 of 5 plugins could not be upgraded due to transitive dependency conflicts (`flutter_rust_bridge` version conflict for `audiotags`; `win32` version conflict for `package_info_plus`, `share_plus`, and `wakelock_plus`). Only `terminate_restart` was migrated from git fork to pub `^1.1.0`.
   - **Recommendation**: Address in a future change when plugin dependencies are compatible.

3. **R6: Pre-existing analyzer warning**
   - **Area**: `lib/services/audio_handler.dart:286`
   - **Description**: `experimental_member_use` on `LockCachingAudioSource` — pre-existing, not caused by this change.
   - **Recommendation**: Accept as known, or address in a separate cleanup.

4. **R7: Plugin-level KGP warnings in build output**
   - **Area**: Build output
   - **Description**: Flutter warns about 5 plugins applying KGP. All 5 are upstream plugins that haven't migrated to built-in Kotlin yet. The app module itself does NOT apply KGP.
   - **Recommendation**: Accept as upstream limitation. Flutter 3.5+ will hard-error; monitor plugin updates.

---

## Follow-ups

1. **Fix R3 regression**: Restore `android/gradle.properties` to committed state (remove `android.builtInKotlin=false` and `android.newDsl=false` lines) — this is required before archiving.
2. **Track upstream plugins**: Create an issue/task to monitor `audiotags`, `package_info_plus`, `share_plus`, and `wakelock_plus` for built-in Kotlin support when transitive dep conflicts are resolved.
3. **Monitor Flutter 3.5 timeline**: The plugin KGP warnings will become errors in Flutter 3.5+ — plan accordingly.

---

## Next Recommended

`resolve-blockers` — Fix the R3 regression (android/gradle.properties working tree), then archive.
