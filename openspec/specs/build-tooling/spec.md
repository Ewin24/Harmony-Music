# Build Tooling

## Purpose

Keep the build infrastructure on versions supported by current and future Flutter
releases. The current versions (Gradle 8.9, AGP 8.6, Kotlin 2.1) are nearing the
end of Flutter support.

## Requirements

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

### Requirement: No Manual KGP Application

The Android app module MUST NOT apply the Kotlin Gradle Plugin (`kotlin-android`) manually.
Flutter's built-in Kotlin integration handles Kotlin compilation automatically.

#### Scenario: kotlin-android absent from app build.gradle plugins

- GIVEN the project root
- WHEN reading `android/app/build.gradle`
- THEN the plugins block SHALL NOT contain `id "kotlin-android"`

### Requirement: Kotlin Compiler DSL

The Android app module MUST use the Kotlin compiler options DSL instead of the
deprecated `kotlinOptions` syntax. The target MUST be `JvmTarget.JVM_17`.

#### Scenario: Kotlin DSL in app build.gradle

- GIVEN the project root
- WHEN reading `android/app/build.gradle`
- THEN the file SHALL contain `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }`
- AND the file SHALL NOT contain `kotlinOptions {`

### Requirement: Built-in Kotlin Enabled

The project MUST enable Flutter's built-in Kotlin mode. The `android.builtInKotlin`
property SHALL NOT be set to `false` in `android/gradle.properties`.

#### Scenario: No built-in Kotlin opt-out flag

- GIVEN the project root
- WHEN searching for `android.builtInKotlin` in `android/gradle.properties`
- THEN the search SHALL return 0 matching lines

### Requirement: Plugin Built-in Kotlin Compatibility

All plugins that previously applied KGP manually MUST be upgraded to versions that
support Flutter's built-in Kotlin.

| Plugin | Minimum Version | Notes |
|--------|----------------|-------|
| audiotags | ^1.4.5 | |
| package_info_plus | ^10.1.0 | Major bump; API may have changed |
| share_plus | ^13.1.0 | Major bump; API may have changed |
| wakelock_plus | ^1.6.1 | |
| terminate_restart | ^1.1.0 or compatible fork | If fork outdated, fall back to pub |

#### Scenario: Plugin versions support built-in Kotlin

- GIVEN the project root
- WHEN reading `pubspec.yaml`
- THEN `audiotags` SHALL be at least `1.4.5`
- AND `package_info_plus` SHALL be at least `10.1.0`
- AND `share_plus` SHALL be at least `13.1.0`
- AND `wakelock_plus` SHALL be at least `1.6.1`
- AND `terminate_restart` SHALL resolve to a version that does not apply KGP

### Requirement: Built-in Kotlin Build Integrity

`flutter build apk --debug` MUST succeed after migrating to built-in Kotlin.

#### Scenario: Debug APK builds with built-in Kotlin

- GIVEN the built-in Kotlin migration is complete (R1 through R4 satisfied)
- WHEN running `flutter build apk --debug`
- THEN the command SHALL exit with code 0
- AND an APK SHALL exist at `build/app/outputs/flutter-apk/app-debug.apk`

### Requirement: Built-in Kotlin Analyze Integrity

`flutter analyze` MUST remain clean (0 errors, 0 warnings) after the migration.

#### Scenario: Analyzer clean after migration

- GIVEN the built-in Kotlin migration is complete
- WHEN running `flutter analyze`
- THEN the command SHALL report no errors and no warnings

### Requirement: No KGP Warnings in Build Output

The build output MUST NOT contain any warning about manually applying the Kotlin
Gradle Plugin.

#### Scenario: Build output free of KGP plugin warnings

- GIVEN the built-in Kotlin migration is complete
- WHEN running `flutter build apk --debug`
- THEN the build output SHALL NOT contain the phrase "applies the Kotlin Gradle Plugin"

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
