# dev-environment-setup Specification

## Purpose

Harmony-Music cannot build, analyze, or verify locally without a working Flutter
toolchain. This spec defines the requirements that MUST be met for a developer
to set up a build-capable environment from a clean machine. Every downstream SDD
change depends on this capability existing first.

## Requirements

### Requirement: Flutter SDK Availability

The Flutter SDK SHALL be installed on the developer's PATH at a stable 3.24.x
version (target: 3.24.2).

#### Scenario: Correct Flutter version reported

- GIVEN a fresh Windows environment with Flutter installed on PATH
- WHEN the developer runs `flutter --version`
- THEN the output SHALL report Flutter `3.24.x` stable channel and the command
  SHALL exit with code 0

#### Scenario: Flutter doctor reports no blocking issues

- GIVEN Flutter SDK 3.24.x is on PATH and Android SDK is configured
- WHEN the developer runs `flutter doctor`
- THEN the output SHALL show no red `[X]` blocking issues for Android toolchain
  and the command SHALL exit with code 0

### Requirement: Submodule Resolution

The `.flutter` submodule (tracking `https://github.com/flutter/flutter.git`)
SHALL be resolved, either via `git submodule update --init` or through a
documented manual clone workaround.

#### Scenario: Submodule init succeeds

- GIVEN the project root with `.gitmodules` present and SSH/HTTPS git access
- WHEN the developer runs `git submodule update --init`
- THEN `.flutter/` SHALL contain Flutter SDK files and `flutter --version`
  executed from `.flutter/bin/` SHALL report a valid version

#### Scenario: Manual clone fallback documented

- GIVEN submodule init fails or the developer prefers a system-wide install
- WHEN the developer follows the documented manual clone steps in
  `CONTRIBUTING.md`
- THEN an alternate Flutter SDK path SHALL be functional and referenced in docs

### Requirement: Dependency Resolution

All project dependencies SHALL resolve via `flutter pub get` without errors.

#### Scenario: pub get resolves all dependencies

- GIVEN the project root with `pubspec.yaml` and `pubspec.lock` present
- WHEN the developer runs `flutter pub get`
- THEN the command SHALL exit with code 0, all dependencies SHALL be fetched,
  and `pubspec.lock` SHALL be created or updated

### Requirement: Custom Fork Resolution

Git-pinned custom forks SHALL resolve during `flutter pub get`. The following
forks MUST be reachable from the developer's environment:

| Package | Repo | Pinned Ref |
|---------|------|------------|
| `youtube_explode_dart` | anandnet/youtube_explode_dart | `1d9ec9ba...` |
| `just_audio_media_kit` | anandnet/just_audio_media_kit | `6672eb82...` |
| `sidebar_with_animation` | anandnet/animated_side_bar | `b53567a4...` |
| `terminate_restart` | anandnet/terminate_restart | `eb505e07...` |

#### Scenario: All custom forks resolve

- GIVEN git is installed and the developer has network access to GitHub
- WHEN `flutter pub get` completes
- THEN each custom fork SHALL be cloned to the pub cache and referenced by
  its pinned commit SHA in `pubspec.lock`

#### Scenario: Fork resolution failure documented

- GIVEN a custom fork is unreachable (e.g., network restriction)
- WHEN `flutter pub get` fails with a git clone error for that fork
- THEN `CONTRIBUTING.md` SHALL document the error, the affected fork, and
  troubleshooting steps

### Requirement: Static Analysis

`flutter analyze` SHALL pass with zero errors from a clean setup.

#### Scenario: Analyze reports zero issues

- GIVEN all dependencies are resolved and Flutter SDK is on PATH
- WHEN the developer runs `flutter analyze` from the project root
- THEN the command SHALL report `No issues found!` and SHALL exit with code 0

### Requirement: APK Build

`flutter build apk --debug` SHALL produce a valid APK artifact.

#### Scenario: Debug APK built successfully

- GIVEN Flutter SDK is on PATH, Android SDK is configured, and all
  dependencies are resolved
- WHEN the developer runs `flutter build apk --debug`
- THEN the command SHALL exit with code 0 and an APK SHALL exist at
  `build/app/outputs/flutter-apk/app-debug.apk`

### Requirement: Editor Configuration

A `.vscode/settings.json` SHALL exist at the project root with
Flutter-recommended workspace settings.

#### Scenario: VS Code settings file present

- GIVEN the project root
- WHEN a developer opens the project in VS Code
- THEN `.vscode/settings.json` SHALL configure Flutter SDK path, Dart analyzer,
  and recommended extensions

### Requirement: Setup Documentation

`CONTRIBUTING.md` SHALL exist and SHALL cover the full setup path: SDK install,
submodule resolution, dependency fetch, analyze, build, and common
troubleshooting. A developer following it from a clean machine MUST be able to
reach a successful build without external guidance.

#### Scenario: End-to-end setup from docs

- GIVEN a clean Windows machine with git and an internet connection
- WHEN the developer follows every step in `CONTRIBUTING.md` sequentially
- THEN `flutter analyze` SHALL report 0 issues AND `flutter build apk --debug`
  SHALL produce a valid APK

## Out of Scope

- Tests (separate SDD change)
- UI or feature modifications
- Dependency version upgrades beyond what is required to build
- CI workflow changes (`.github/workflows/`)
- Desktop build targets (Windows, Linux)

## Non-Functional Requirements

| Concern | Requirement |
|---------|------------|
| **Reproducibility** | All setup steps SHALL be documented such that a developer can reproduce from a clean OS install without prior knowledge |
| **Idempotency** | Each setup step SHALL be safe to re-run without corrupting the environment |
| **Documentation quality** | `CONTRIBUTING.md` SHALL include exact commands (copy-paste ready), expected outputs, and a troubleshooting section for each step |
