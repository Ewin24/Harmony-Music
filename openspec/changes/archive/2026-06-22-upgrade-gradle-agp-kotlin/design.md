# Design: Upgrade Gradle, AGP, and Kotlin to Flutter 3.5+ Supported Versions

## Technical Approach

Three independent version bumps in their respective Gradle config files. No code changes, no behavior changes — pure build-infrastructure maintenance. The proposal identified the target versions (Gradle 8.9 → 8.14, AGP 8.6 → 8.11.1, Kotlin 2.1 → 2.2.20) and the specs define 6 verifiable requirements (file reads, build integrity, deprecation-free output). The design maps each spec requirement to exact `Modify` operations on two files.

## Architecture Decisions

### Decision: Target Versions

| Option | Tradeoff | Decision |
|--------|----------|----------|
| **Gradle 8.14** (binary dist) | Smaller download than `-all`; no source jars for IDE debug | Use `-bin` to match existing convention |
| **AGP 8.11.1** | 8.11.x is the latest stable patch; Flutter 3.5 minimum | Use 8.11.1 — no reason to go lower |
| **Kotlin 2.2.20** | 2.2.x is Flutter 3.5 minimum; 2.2.20 is latest stable patch | Use 2.2.20 |

### Decision: Single vs. Staged Bumps

| Option | Tradeoff | Decision |
|--------|----------|----------|
| **Single commit** | Clean atomic diff, but harder to bisect if breakage | Single commit. All three bumps are tested together and each is independently revertible in its own file. |
| **Three commits** | Max bisect precision | Rejected — over-engineering for 3-line change. Rollback is just restoring 3 version strings. |

### Decision: No Flutter SDK / NDK changes

The specs do not require Flutter SDK or NDK version changes. The existing `ndkVersion = "26.1.10909125"` in `app/build.gradle` is compatible with AGP 8.11.1. No additional config changes needed.

## Data Flow

```
gradle-wrapper.properties (Gradle URL)
  → Gradle wrapper downloads 8.14 distribution on first build
  → Gradle resolves plugins from settings.gradle pluginManagement

settings.gradle (AGP 8.11.1, Kotlin 2.2.20)
  → AGP plugin applied to :app module via app/build.gradle
  → Kotlin Gradle Plugin applied to :app via kotlin-android plugin
  → flutter build apk --debug produces app-debug.apk
```

No runtime data flow changes — this is build-time only.

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `android/gradle/wrapper/gradle-wrapper.properties` | Modify | Line 3: `gradle-8.9-bin.zip` → `gradle-8.14-bin.zip` |
| `android/settings.gradle` | Modify | Line 21: AGP `8.6.0` → `8.11.1`; Line 22: Kotlin `2.1.0` → `2.2.20` |

Total: 3 version strings across 2 files. No new files, no deletions.

## Interfaces / Contracts

No new interfaces. The `settings.gradle` plugin declarations remain unchanged in structure — only version strings change. The `gradle-wrapper.properties` format is identical.

## Testing Strategy

Per the spec's 6 requirements, verification is entirely external (file-level + build-level):

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Config validation | All 3 version strings read correctly | Read each file and assert target version present |
| Build integrity | `flutter build apk --debug` exits 0 | Run `flutter clean && flutter build apk --debug` |
| Analyzer integrity | `flutter analyze` has no new issues | Run `flutter analyze` and compare to pre-upgrade baseline |
| Deprecation audit | No Gradle/AGP/Kotlin version warnings | Scan build output for deprecation strings |
| APK artifact | APK exists at expected path | Check `build/app/outputs/flutter-apk/app-debug.apk` |

## Migration / Rollout

No migration required. Each version bump is independently revertible by restoring the single version string in its respective file:

- Gradle: revert `gradle-wrapper.properties` line 3 → `gradle-8.9-bin.zip`
- AGP: revert `settings.gradle` line 21 → `8.6.0`
- Kotlin: revert `settings.gradle` line 22 → `2.1.0`

## Open Questions

- None. All three target versions are confirmed stable, the files are read, and the edit locations are precise.
