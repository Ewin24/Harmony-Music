# Design: Flutter Dev Environment Setup

## Technical Approach

Install a system-wide Flutter SDK 3.24.2 + Android command-line tools + JDK 17, resolve git submodule and custom fork dependencies, then validate via `flutter analyze` and `flutter build apk --debug`. Document every step in `CONTRIBUTING.md` + `docs/setup.md` so a new contributor can reproduce from a clean Windows machine.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                    Harmony-Music Dev Environment                  │
│                                                                   │
│  ┌─────────────────┐   ┌──────────────────┐   ┌──────────────┐  │
│  │  Flutter SDK     │   │   Android SDK    │   │   JDK 17     │  │
│  │  (3.24.2)        │   │  (cmdline-tools) │   │  (Temurin)   │  │
│  │  C:\src\flutter  │   │  C:\Users\<u>\   │   │  JAVA_HOME   │  │
│  └────────┬─────────┘   └────────┬─────────┘   └──────┬───────┘  │
│           │                      │                     │         │
│           │      ┌───────────────┴─────────────────────┘         │
│           │      │                                                 │
│           ▼      ▼                                                 │
│  ┌────────────────────────────┐                                   │
│  │     ./gradlew assembleDebug │──→ app-debug.apk                 │
│  │     (AGP 8.6.0, Kotlin 2.1)│    build/app/outputs/flutter-apk/│
│  └────────────┬───────────────┘                                   │
│               │                                                    │
│               │  ┌──────────────────────────┐                     │
│               │  │  Flavors of Flutter SDK  │                     │
│               └──│  1. System install (PATH)│── Primary           │
│                  │  2. .flutter submodule   │── Fallback          │
│                  └──────────────────────────┘                     │
│                                                                   │
│  ┌────────────────────────────────────────────────────┐          │
│  │  Dependency Resolution Pipeline                    │          │
│  │                                                    │          │
│  │  pubspec.yaml (4 git forks) ── flutter pub get ──► │          │
│  │       │           │          │          │          │          │
│  │  youtube_explode_dart  just_audio_media_kit        │          │
│  │  sidebar_with_animation  terminate_restart         │          │
│  └────────────────────────────────────────────────────┘          │
└──────────────────────────────────────────────────────────────────┘
```

## Architecture Decisions

### Decision: Flutter SDK install strategy

| Option | Tradeoff | Decision |
|--------|----------|----------|
| `.flutter` submodule as primary | 1.5GB submodule, slow clone, unusual workflow | ❌ Rejected |
| **System-wide install** (`C:\src\flutter`) | Standard workflow, `flutter doctor` expects PATH, typical for Flutter devs | ✅ **Chosen** |
| FVM (Flutter Version Management) | Adds extra tooling dependency, useful for multiple projects | ❌ Deferred |

**Choice**: System-wide install from `storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.2-stable.zip`

**Rationale**: The `.flutter` submodule is empty and impractical (1.5GB submodule of the entire Flutter repo). System install is the standard Flutter workflow. The submodule config is kept as a documented fallback.

### Decision: Android SDK strategy

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Require Android Studio | 2GB install, GUI-heavy, many CLI-only devs won't have it | ❌ Rejected |
| **Command-line tools only** | ~150MB, no IDE, `sdkmanager` CLI, must accept licenses manually | ✅ **Chosen (primary)** |
| Both documented | Covers both workflows, more documentation | ✅ **Documented as alternative** |

**Choice**: Install command-line tools + `sdkmanager` to fetch platform `android-35`, build-tools, and NDK. Document Android Studio as an alternative.

**Rationale**: AGP 8.6.0 requires compileSdk 35 (Flutter 3.24 default). `flutter doctor` with command-line tools is the minimal path. Full Android Studio is documented for those who prefer it.

### Decision: JDK version

**Choice**: JDK 17 (Eclipse Temurin or Oracle OpenJDK)

**Alternatives considered**: JDK 21 (LTS, forward-compatible), JDK 11 (EOL for AGP 8.x)

**Rationale**: `android/app/build.gradle` sets `JavaVersion.VERSION_17` for both source and target. AGP 8.6.0 + Kotlin 2.1.0 require Java 17+. JDK 17 is the minimum required version. JDK 21 works but is not required.

### Decision: .flutter submodule handling

**Choice**: Keep `.gitmodules` config. Document two paths:
1. **Primary**: System Flutter SDK on PATH (recommended)
2. **Fallback**: `git submodule update --init` (or manual clone if submodule fails)

**Rationale**: The submodule references the full Flutter repo. Most devs want system install. But removing the submodule has cascading git history impacts. Document both and let the contributor choose.

### Decision: Build target

**Choice**: APK (debug) as primary. Document Windows desktop as optional.

**Rationale**: Spec requires `flutter build apk --debug`. APK is the most portable validation. Windows desktop (`flutter build windows`) requires Visual Studio Build Tools with C++ workload (~6GB). Validate one target, document the others.

## Data Flow

```
Developer Machine
       │
       ├──(1) Install Flutter SDK 3.24.2 ──► PATH + flutter doctor
       │
       ├──(2) Install Android cmdline-tools ──► sdkmanager "platforms;android-35"
       │                                          sdkmanager "build-tools;35.0.0"
       │                                          flutter doctor --android-licenses
       │
       ├──(3) Install JDK 17 ──► JAVA_HOME + PATH
       │
       ├──(4) git clone + submodule handling
       │       │
       │       ├── System Flutter on PATH ──► flutter pub get (uses PATH SDK)
       │       └── .flutter submodule ──► git submodule update --init
       │                                     └── flutter pub get (uses .flutter/bin)
       │
       ├──(5) flutter pub get
       │       │
       │       ├── pub.dev hosted packages ──► pub cache download
       │       ├── 4 git forks ──► git clone via pub (pinned SHAs)
       │       └── pubspec.lock ──► created / validated
       │
       ├──(6) flutter analyze ──► 0 errors
       │
       └──(7) flutter build apk --debug ──► build/app/outputs/flutter-apk/app-debug.apk
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `.vscode/settings.json` | Create | Flutter SDK path hint, Dart analyzer config, recommended extensions |
| `CONTRIBUTING.md` | Create | Root-level contributor setup guide (5 min read, quick reference) |
| `docs/setup.md` | Create | Deep setup document with prerequisites, commands, expected outputs, troubleshooting |
| `README.md` | Modify | Add setup/building section linking to `CONTRIBUTING.md` and `docs/setup.md` |
| `.flutter/` | Modify | `git submodule update --init` populates directory (or documented clone fallback) |
| `pubspec.lock` | Modify | Committed after first successful `pub get` (pins fork SHAs) |

## Interfaces / Contracts

No new interfaces defined. This change sets up the toolchain around existing interfaces:

- **Flutter SDK contract**: `flutter` CLI accessible on `PATH`, version `3.24.x`
- **Android SDK contract**: `ANDROID_HOME` (or `ANDROID_SDK_ROOT`) pointing to SDK root with `platforms/android-35` and `build-tools/35.0.0`
- **JDK contract**: `JAVA_HOME` pointing to JDK 17, `java` on `PATH`

## Feature Flags / Configuration

None. This is foundational environment setup, not runtime behavior.

| Concern | Approach |
|---------|----------|
| Flutter SDK path | `local.properties` (generated by Flutter) + PATH env var |
| Android SDK path | `local.properties` (via `flutter config --android-sdk`) |
| JDK path | `JAVA_HOME` env var + `local.properties` (via `flutter config --jdk-dir`) |

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Smoke | `flutter --version` | Exit 0, output contains `3.24.x` |
| Smoke | `flutter doctor` | All Android toolchain items show `[✓]`, exit 0 |
| Dependency | `flutter pub get` | Exit 0, all 4 git forks resolved in `.pub-cache` |
| Static analysis | `flutter analyze` | `No issues found!`, exit 0 |
| Build | `flutter build apk --debug` | Exit 0, `app-debug.apk` exists at expected path |

## Migration / Rollout

No migration required. This is a new capability — state does not need migration.

**Rollback plan** (from proposal):
- Remove Flutter from PATH
- Delete `CONTRIBUTING.md`, `docs/setup.md`, `.vscode/settings.json`
- Restore `.flutter` via `git checkout -- .flutter`
- Revert `README.md` changes

## Verification Plan (Smoke Test Sequence)

```bash
# 1. SDK version
flutter --version
# Expected: Flutter 3.24.x, Dart 3.5.x, stable channel

# 2. Doctor
flutter doctor
# Expected: No [X] for Android toolchain, exit 0

# 3. Submodule resolution (if using submodule path)
git submodule update --init
# Expected: .flutter/bin/flutter --version works

# 4. Dependency resolution
flutter pub get
# Expected: Exit 0, "Process finished with exit code 0"

# 5. Static analysis
flutter analyze
# Expected: "No issues found!", exit 0

# 6. APK build
flutter build apk --debug
# Expected: Exit 0, build/app/outputs/flutter-apk/app-debug.apk exists
```

## Step-by-Step Implementation Order

| Step | Action | Verification |
|------|--------|-------------|
| 1 | Install Flutter SDK (download + extract + PATH) | `flutter --version` |
| 2 | Install Android cmdline-tools + SDK 35 + accept licenses | `flutter doctor` |
| 3 | Install JDK 17 + set JAVA_HOME | `java --version` |
| 4 | Resolve `.flutter` submodule or document manual clone | `.flutter/bin/` has content |
| 5 | Run `flutter pub get` | Exit 0, lock updated |
| 6 | Run `flutter analyze` | "No issues found!" |
| 7 | Run `flutter build apk --debug` | APK at expected path |
| 8 | Write `docs/setup.md` | Document covers all steps |
| 9 | Write `CONTRIBUTING.md` | Concise reference from root |
| 10 | Update `README.md` | Setup section links to docs |
| 11 | Create `.vscode/settings.json` | Flutter tooling configured |

## Edge Cases / Failure Modes

| Failure Mode | Detection | Mitigation |
|-------------|-----------|------------|
| Flutter download interrupted | Partial ZIP | Delete partial, re-download (idempotent) |
| Android SDK missing | `flutter doctor` shows `[X]` | Install cmdline-tools + SDK 35 |
| JDK 17 not found | Gradle build fails with Java version error | Install Temurin JDK 17, set JAVA_HOME |
| Git fork unreachable | `flutter pub get` fails with git clone error | `pub cache repair` + retry; fallback: clone manually to pub cache |
| `.flutter` submodule empty | `ls .flutter/` shows nothing | `git submodule update --init` or manual `git clone` to `.flutter/` |
| Windows build missing MSVC | `flutter build windows` fails | Install VS Build Tools with "Desktop development with C++" |
| Antivirus blocking Dart/Flutter | `flutter` commands hang | Add Flutter SDK directory to AV exclusions |
| Path too long (Windows) | Git clone errors on deep paths | Enable `git config --system core.longpaths true` |
| `local.properties` not generated | Gradle fails to find Flutter SDK | Run `flutter pub get` first to auto-generate |

## Open Questions

- [ ] What is the actual Android SDK level (`flutter.compileSdkVersion`) resolved by Flutter 3.24.2? Need to verify `flutter doctor -v` output to confirm `android-35`.
- [ ] Does the `ndkVersion 26.1.10909125` pin require manual NDK install, or does `sdkmanager` include it with `ndk-bundle`?
- [ ] Are the 4 custom forks still accessible at the pinned SHAs? Need network verification during implementation.
