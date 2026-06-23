# Proposal: Migrate to Built-in Kotlin (drop legacy KGP plugin application)

## Intent

Flutter 3.5+ will fail to build apps that apply the Kotlin Gradle Plugin (KGP) manually. The app currently applies `kotlin-android` in `app/build.gradle`, and 5 plugins still apply KGP. Migrating now prevents future build failures and aligns with Flutter's modern Gradle integration.

## Scope

### In Scope
- Remove `kotlin-android` from `android/app/build.gradle` plugins block
- Migrate `kotlinOptions` block to `kotlin { compilerOptions { ... } }` DSL
- Remove `android.builtInKotlin=false` and `android.newDsl=false` from `android/gradle.properties`
- Upgrade 5 plugins to versions compatible with built-in Kotlin
- Verify with `flutter build apk --debug`

### Out of Scope
- Dart code changes
- iOS platform changes
- Other Android plugins not in the warning list
- Flutter SDK version upgrade
- Plugin functional behavior changes (API migration if breaking)

## Capabilities

### New Capabilities
None

### Modified Capabilities
- `build-tooling`: Kotlin version requirement stays (2.2.20), but the Kotlin Gradle Plugin is no longer applied manually — Flutter's built-in Kotlin handles it

## Approach

1. **App build.gradle**: Remove `id "kotlin-android"`, replace `kotlinOptions` with `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }`
2. **gradle.properties**: Remove `android.builtInKotlin=false` and `android.newDsl=false` (enables built-in Kotlin mode)
3. **Plugin upgrades**:
   - `audiotags`: 1.4.1 → ^1.4.5
   - `package_info_plus`: ^8.0.0 → ^10.1.0
   - `share_plus`: ^10.1.4 → ^13.1.0
   - `wakelock_plus`: ^1.3.3 → ^1.6.1
   - `terminate_restart`: git fork → check if fork PR merged; fallback to latest pub 1.1.0
4. Verify: `flutter clean && flutter build apk --debug` — check no KGP warnings remain

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `android/app/build.gradle` | Modified | Remove KGP plugin; update kotlinOptions |
| `android/gradle.properties` | Modified | Remove builtInKotlin/newDsl flags |
| `pubspec.yaml` | Modified | Upgrade 5 plugin versions |
| `openspec/specs/build-tooling/spec.md` | Modified | Update Kotlin requirement to reflect built-in Kotlin behavior |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Plugin API breakage on major versions | Med | Check changelogs; test build first; defer API migration to separate change if needed |
| Git-forked `terminate_restart` may not support built-in Kotlin | Med | If fork is outdated, pin to latest pub version; test restart/terminate functionality |
| `kotlin { compilerOptions { ... } }` DSL requires newer AGP | Low | Already on AGP 8.11.1 — compatible |

## Rollback Plan

Revert `android/app/build.gradle`, `android/gradle.properties`, and `pubspec.yaml` to pre-change state. Restore `android.builtInKotlin=false` and `android.newDsl=false`. The app will build in legacy mode again.

## Dependencies

- Plugin changelogs (ensure no breaking API changes in upgrade paths)
- Flutter SDK availability for build verification

## Success Criteria

- [ ] `flutter build apk --debug` succeeds with no KGP-related warnings
- [ ] `flutter analyze` reports 0 errors
- [ ] No `kotlin-android` plugin applied in any project `build.gradle`
- [ ] `android.builtInKotlin` and `android.newDsl` removed from `gradle.properties`
