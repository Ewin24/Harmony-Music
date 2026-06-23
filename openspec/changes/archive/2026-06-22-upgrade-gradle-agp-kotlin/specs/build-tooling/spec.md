# Delta for build-tooling

## Purpose

Keep the build infrastructure on versions supported by current and future Flutter
releases. The current versions (Gradle 8.9, AGP 8.6, Kotlin 2.1) are nearing the
end of Flutter support.

## ADDED Requirements

### Requirement: Gradle Version

The system MUST use Gradle 8.14.0 or higher in
`android/gradle/wrapper/gradle-wrapper.properties`.

#### Scenario: Gradle wrapper points to supported version

- GIVEN the project root
- WHEN reading `android/gradle/wrapper/gradle-wrapper.properties`
- THEN the `distributionUrl` SHALL reference a Gradle version `>= 8.14.0`

### Requirement: Android Gradle Plugin Version

The system MUST use Android Gradle Plugin 8.11.1 or higher, declared in
`android/settings.gradle` or `android/build.gradle`.

#### Scenario: AGP version meets minimum

- GIVEN the project root
- WHEN reading `android/settings.gradle` or `android/build.gradle`
- THEN the AGP version declared SHALL be `>= 8.11.1`

### Requirement: Kotlin Version

The system MUST use Kotlin 2.2.20 or higher, declared in
`android/settings.gradle` or `android/build.gradle`.

#### Scenario: Kotlin version meets minimum

- GIVEN the project root
- WHEN reading `android/settings.gradle` or `android/build.gradle`
- THEN the Kotlin version SHALL be `>= 2.2.20`

### Requirement: Build Integrity

`flutter build apk --debug` MUST succeed after the version upgrades.

#### Scenario: Debug APK builds cleanly

- GIVEN the upgraded Gradle, AGP, and Kotlin versions are in place
- WHEN running `flutter build apk --debug`
- THEN the command SHALL exit with code 0 and an APK SHALL exist at
  `build/app/outputs/flutter-apk/app-debug.apk`

### Requirement: Analyze Integrity

`flutter analyze` MUST remain clean (0 errors, 0 warnings) after the version
upgrades.

#### Scenario: Analyzer reports no issues

- GIVEN the upgraded versions are in place
- WHEN running `flutter analyze`
- THEN the command SHALL report no new errors or warnings compared to the
  pre-upgrade baseline

### Requirement: No Deprecation Warnings

The build output MUST NOT contain deprecation warnings about Gradle, AGP, or
Kotlin versions.

#### Scenario: Build output is free of version deprecation warnings

- GIVEN the upgraded versions are in place
- WHEN running `flutter build apk --debug`
- THEN the build output SHALL contain no warnings about Gradle, AGP, or Kotlin
  version deprecation

## Out of Scope

- Plugin code changes (separate change)
- Flutter SDK upgrade
- Third-party plugin version upgrades
- Functional or behavioral changes

## Non-Functional Requirements

| Concern | Requirement |
|---------|-------------|
| **Diff size** | The change SHALL be a minimal diff affecting only version strings in two files |
| **Reviewability** | The entire change SHALL fit within a single PR under 10 changed lines |
| **Reversibility** | All version bumps SHALL be revertible by restoring the previous version strings |
