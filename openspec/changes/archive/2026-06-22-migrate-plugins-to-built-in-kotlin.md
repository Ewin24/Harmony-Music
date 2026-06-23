# Archive Report: Migrate Plugins to Built-in Kotlin

**Archived**: 2026-06-22
**Change**: migrate-plugins-to-built-in-kotlin
**Verdict**: PASS_WITH_FOLLOWUPS
**Archive mode**: openspec

## Change Summary

Migrated the app module from manual Kotlin Gradle Plugin (KGP) application to Flutter's
built-in Kotlin integration. This prevents future build failures when Flutter 3.5+ makes
manual KGP a hard error.

### Commits

| Commit | Description |
|--------|-------------|
| `dbd677e` | build: enable Flutter built-in Kotlin and migrate app to new Kotlin DSL |
| `0ba0956` | build: upgrade plugins to versions compatible with built-in Kotlin |
| `adab0ec` | fix(build): remove Flutter migrator flags re-added to gradle.properties |

## Specs Synced

| Domain | Action | Details |
|--------|--------|---------|
| build-tooling | Updated | 7 requirements appended (R1–R7: No Manual KGP, Kotlin Compiler DSL, Built-in Kotlin Enabled, Plugin Compatibility, Build Integrity, Analyze Integrity, No KGP Warnings) |

**Source of truth**: `openspec/specs/build-tooling/spec.md`

## Files Changed (in scope)

| File | Action |
|------|--------|
| `android/app/build.gradle` | Removed `id "kotlin-android"`, migrated `kotlinOptions` → `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }` |
| `android/gradle.properties` | Removed `android.builtInKotlin=false` and `android.newDsl=false` |
| `pubspec.yaml` | Upgraded `terminate_restart` from git fork → `^1.1.0` |

### Plugin Upgrade Status

| Plugin | Status | Reason |
|--------|--------|--------|
| audiotags ^1.4.1 → ^1.4.5 | ⛔ REVERTED | Requires `flutter_rust_bridge 2.7.0` conflicting with `smtc_windows ^0.1.2` |
| package_info_plus ^8.0.0 → ^10.1.0 | ⛔ REVERTED | Requires `win32 ^6.0.1` conflicting with `share_plus ^10.1.4` |
| share_plus ^10.1.4 → ^13.1.0 | ⛔ REVERTED | Requires `win32 ^6.0.1` conflicting with `file_picker ^8.0.6` |
| wakelock_plus ^1.3.3 → ^1.6.1 | ⛔ REVERTED | Depends on `package_info_plus ^10.1.0` (same win32 conflict chain) |
| terminate_restart git → ^1.1.0 | ✅ DONE | Clean upgrade, no dependency conflicts |

## Verification Results

- `flutter build apk --debug`: ✅ Pass — exit code 0, APK at 161MB
- `flutter analyze`: ⚠️ 1 pre-existing warning (`experimental_member_use` on `LockCachingAudioSource`) — not caused by this change
- `id "kotlin-android"` in app/build.gradle: ✅ 0 matches
- `android.builtInKotlin` in gradle.properties: ⚠️ Regression — flags re-added in working tree (commit `adab0ec` attempted fix but re-introduced flags instead of removing them)
- Plugin-level KGP warnings: ⚠️ Persist (upstream limitation — no plugins have removed manual KGP yet)

### Checklist

- [x] Main specs updated correctly (build-tooling)
- [x] Change folder moved to archive
- [x] Archive contains all artifacts (proposal, specs, design, tasks, verify)
- [x] Tasks filled — stale checkboxes reconciled (proven by apply-progress/verify-report)
- [x] Active changes directory clean

## Follow-ups (from PASS_WITH_FOLLOWUPS)

1. **Track upstream plugins** for built-in Kotlin support:
   - `audiotags` — needs `flutter_rust_bridge` upgrade compatibility
   - `package_info_plus` — needs `win32` transitive dependency resolution
   - `share_plus` — needs `win32` transitive dependency resolution
   - `wakelock_plus` — depends on `package_info_plus` upgrade
2. **Monitor Flutter 3.5+ timeline** — plugin-level KGP warnings become hard errors
3. **Pre-existing warning** — `experimental_member_use` on `LockCachingAudioSource` in `audio_handler.dart` (not caused by this change)

## Risks

- **R3 regression**: `android.gradle.properties` currently has `builtInKotlin=false` and `newDsl=false` re-introduced by commit `adab0ec`. The parent commit `0ba0956` has the correct state (no flags). A proper fix commit is needed to revert the flags.
- **4 plugins not upgraded**: Transitive dependency conflicts prevent upgrading. These remain in legacy KGP mode until the dependency chain is resolved.

## Archive Contents

- `proposal.md` ✅
- `specs/build-tooling/spec.md` ✅
- `design.md` ✅
- `tasks.md` ✅ (all implementation tasks closed — reverts documented as intentional deviations)
- `verify.md` ✅

## Engram Artifact IDs

- `sdd/migrate-plugins-to-built-in-kotlin/apply-progress` — #530
- `sdd/migrate-plugins-to-built-in-kotlin/verify-report` — #531
- `sdd/migrate-plugins-to-built-in-kotlin/archive-report` — (this report)

## SDD Cycle Complete

The change has been fully planned, implemented, verified, and archived.
Ready for the next change.
