# Tasks: Upgrade Gradle, AGP, and Kotlin to Flutter 3.5+ Supported Versions

## Review Workload Forecast

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

| Field | Value |
|-------|-------|
| Estimated changed lines | 3-5 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Not needed — single commit |
| Delivery strategy | ask-always |
| Chain strategy | pending |

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Bump all 3 versions + verify build | PR 1 (single commit) | Base: main. Must be tested together since build success requires all three. |

## Phase 1: Version Bumps (Single Commit)

- [x] 1.1 Edit `android/gradle/wrapper/gradle-wrapper.properties` line 3: `gradle-8.9-bin.zip` → `gradle-8.14-bin.zip`
- [x] 1.2 Edit `android/settings.gradle` line 21: AGP `'8.6.0'` → `'8.11.1'`
- [x] 1.3 Edit `android/settings.gradle` line 22: Kotlin `"2.1.0"` → `"2.2.20"`
- [x] 1.4 Commit as single atomic change: `build: upgrade Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20`

## Phase 2: Build Verification

- [x] 2.1 Run `flutter clean` from project root
- [x] 2.2 Run `flutter build apk --debug` — verify exit 0 and APK exists at `build/app/outputs/flutter-apk/app-debug.apk`
- [x] 2.3 Run `flutter analyze` — verify 0 errors, 0 warnings
- [x] 2.4 Scan build output for Gradle/AGP/Kotlin deprecation warnings — verify none
- [x] 2.5 If build fails, diagnose and fix (AGP/Kotlin plugin compatibility), then repeat steps 2.1-2.4
