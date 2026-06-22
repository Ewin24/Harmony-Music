# Delta for deprecation-cleanup

## ADDED Requirements

### Requirement: Color API Modernization — withOpacity

The system MUST use `withValues(alpha: x)` instead of the deprecated `withOpacity(x)` on all `Color` instances in `lib/`.

#### Scenario: No withOpacity calls remain

- GIVEN the project's `lib/` directory
- WHEN searching `.dart` files for `withOpacity(`
- THEN zero matches SHALL exist

### Requirement: Color API Modernization — .value getter

The system MUST use `toARGB32()` or individual channel getters (`.a`, `.r`, `.g`, `.b`) instead of the deprecated `Color.value` getter.

#### Scenario: No Color.value in deprecated access context

- GIVEN `lib/ui/utils/theme_controller.dart`
- WHEN reading the file for `Color.value` accesses
- THEN zero deprecated `.value` calls SHALL remain

### Requirement: SystemUiOverlayStyle Legacy Boolean Removal

The system MUST NOT set deprecated boolean properties on `SystemUiOverlayStyle`. Deprecated properties include: `statusBarColor`, `statusBarIconBrightness`, `statusBarBrightness`, `systemNavigationBarColor`, `systemNavigationBarDividerColor`, `systemNavigationBarIconBrightness`.

#### Scenario: No deprecated overlay booleans remain

- GIVEN the project's `lib/` directory
- WHEN searching `.dart` files for the deprecated boolean property names
- THEN zero occurrences SHALL remain in live (non-comment, non-generated) code

### Requirement: ThemeData Constructor Legacy Property Migration

The system MUST NOT pass deprecated named parameters to the `ThemeData()` constructor. Deprecated parameters (`backgroundColor`, `surfaceTint`, `accentColor`, `canvasColor`, `cardColor`, `dialogBackgroundColor`, `primaryColorLight`, `primaryColorDark`) SHALL be migrated to `colorScheme` equivalents.

#### Scenario: ThemeData constructor uses colorScheme

- GIVEN `lib/ui/utils/theme_controller.dart`
- WHEN reading each `ThemeData(` call site
- THEN no deprecated constructor parameters SHALL be present

### Requirement: ThemeData Getter Migration to colorScheme

The system MUST access theme colors via `Theme.of(context).colorScheme.*` instead of deprecated getters (`canvasColor`, `backgroundColor`, `cardColor`, `primaryColorLight`, `scaffoldBackgroundColor`, `dividerColor`).

#### Scenario: All theme getter reads use colorScheme

- GIVEN the project's `lib/` directory
- WHEN searching `.dart` files for deprecated ThemeData getter reads
- THEN all theme color access SHALL go through `colorScheme.*` paths

### Requirement: Zero-Analyze Baseline

`flutter analyze` executed from the project root MUST report zero errors, zero warnings, and zero deprecation infos.

#### Scenario: Analyze reports no issues

- GIVEN all deprecation fixes are applied and Flutter SDK is on PATH
- WHEN running `flutter analyze`
- THEN output SHALL end with "No issues found!" and exit code SHALL be 0

### Requirement: Build Integrity Preservation

`flutter build apk --debug` MUST still succeed after all deprecation replacements.

#### Scenario: Debug APK builds cleanly

- GIVEN Flutter SDK is on PATH and dependencies are resolved
- WHEN running `flutter build apk --debug`
- THEN command SHALL exit with code 0 and produce an APK at `build/app/outputs/flutter-apk/app-debug.apk`

### Requirement: Visual Regression Prevention

Default theme rendering (light and dark) MUST NOT regress after API replacements.

#### Scenario: Visual smoke check passes

- GIVEN the app is built and running
- WHEN viewing screens under default light and dark themes
- THEN colors, backgrounds, and overlays SHALL appear visually consistent with the pre-cleanup build

## Out of Scope

- Behavior or feature changes
- Refactors unrelated to deprecation cleanup
- Third-party package deprecation warnings
- Generated or build artifacts
- MD2→MD3 theme architecture migration

## Non-Functional Requirements

| Concern | Requirement |
|---------|------------|
| **Mechanicity** | Replacements SHALL be mechanical: no semantic change to color values, layout, or rendering |
| **Commit granularity** | Each deprecation category SHALL be a separate commit to enable independent revert |
| **Reviewability** | Changes SHALL be hand-edited per hunk; no bulk `dart fix --apply` without prior review |
