# Proposal: Upgrade Gradle, AGP, and Kotlin to Flutter 3.5+ Supported Versions

## Intent

Flutter 3.5 will drop support for Gradle < 8.14, AGP < 8.11.1, and Kotlin < 2.2.20. The current build already warns about impending deprecation. Upgrading now prevents future build failures and unblocks modern Android tooling.

## Scope

### In Scope
- Bump Gradle version in `gradle-wrapper.properties`
- Bump AGP version in `android/settings.gradle`
- Bump Kotlin version in `android/settings.gradle`
- Run `flutter build apk --debug` to verify build succeeds
- Address any build failures caused by the version bumps

### Out of Scope
- Updating Kotlin plugin code in 3rd-party packages (separate change tracked in explore)
- Flutter SDK upgrade
- Dart version bump
- Third-party plugin version bumps (e.g., audio_service, just_audio)
- Any functional or behavioral changes beyond version bumps

## Capabilities

### New Capabilities
None — this is a pure build infrastructure version bump, no new feature capabilities.

### Modified Capabilities
None — no spec-level behavior changes. Pure tooling version upgrades.

## Approach

1. Edit `android/gradle/wrapper/gradle-wrapper.properties`: change `gradle-8.9-bin.zip` → `gradle-8.14-bin.zip`
2. Edit `android/settings.gradle`: bump AGP from `8.6.0` → `8.11.1`, Kotlin from `2.1.0` → `2.2.20`
3. Run `flutter build apk --debug` and verify green build
4. If build fails, diagnose and fix (likely AGP API incompatibility with plugins)

## Current vs Target Versions

| Component | Current | Target |
|-----------|---------|--------|
| Gradle    | 8.9.0   | 8.14.0 |
| AGP       | 8.6.0   | 8.11.1 |
| Kotlin    | 2.1.0   | 2.2.20 |

## Affected Areas

| File | Impact | Change |
|------|--------|--------|
| `android/gradle/wrapper/gradle-wrapper.properties` | Modified | Gradle distribution URL |
| `android/settings.gradle` | Modified | AGP version (line 21), Kotlin version (line 22) |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| AGP 8.11.x API breakage in plugin `audio_service` or `wakelock_plus` | Medium | Pin AGP to latest working minor if 8.11 breaks; check plugin compat |
| Kotlin 2.2.x KGP compiler plugin incompatibility | Medium | Pin to 2.1.x if 5 KGP-legacy plugins fail; address in separate KGP migration |
| Gradle 8.14 task configuration regression | Low | Gradle minor bumps are backward-compatible; verify build passes |
| Flutter SDK not available in this env | Medium | Use static review + CI build as fallback verification |

## Rollback Plan

1. Revert `gradle-wrapper.properties` to `gradle-8.9-bin.zip`
2. Revert `settings.gradle` AGP to `8.6.0` and Kotlin to `2.1.0`
3. Run `flutter clean && flutter build apk --debug` to confirm restoration

## Dependencies

- Flutter SDK with `flutter` on PATH for build verification
- Working Android SDK / NDK configuration

## Success Criteria

- [ ] `flutter build apk --debug` completes successfully with no errors
- [ ] No deprecation warnings about Gradle/AGP/Kotlin versions in build output
- [ ] All three config files show target versions on `git diff`
