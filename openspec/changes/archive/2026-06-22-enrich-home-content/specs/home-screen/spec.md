# Delta for Home Screen Content Loading

## Purpose

Enrich the home screen with more content sections and reduce the vertical gap between QuickPicks and the first middleContent section.

## ADDED Requirements

### Requirement: Default Content Section Count

The system MUST default `noOfHomeScreenContent` to 9 sections on fresh install.

#### Scenario: Default value is 9

- GIVEN a fresh install with default settings
- WHEN the user opens Settings
- THEN `noOfHomeScreenContent` SHALL be 9
- AND the Home screen SHALL fetch at least 9 content sections from the API

### Requirement: Content Section Count Options

The system MUST offer `noOfHomeScreenContent` dropdown options [5, 7, 9, 11, 15].

#### Scenario: Options exclude removed values

- GIVEN the Settings screen
- WHEN the user opens the content-count dropdown
- THEN options SHALL include 5, 7, 9, 11, 15
- AND the value 3 SHALL NOT appear

### Requirement: Reduced Vertical Gap Below QuickPicks

The system SHALL render 8px vertical gap between QuickPicksWidget bottom edge and the next content section.

#### Scenario: Gap is 8px

- GIVEN the Home screen with QuickPicks and middleContent visible
- WHEN measuring vertical space between the QuickPicks bottom edge and the next section's top edge
- THEN the gap SHALL be 8px (previously 20px)

### Requirement: Minimum Visible Sections on Home

When the Home screen renders content, the system SHALL display at least 3 distinct sections.

#### Scenario: Home shows 3 section categories

- GIVEN fresh install with default settings and network available
- WHEN the user opens the Home screen
- THEN QuickPicks, at least one middleContent section, and at least one fixedContent section SHALL be visible

### Requirement: Analyze Integrity

`flutter analyze` executed from the project root MUST report zero errors and zero warnings introduced by this change.

#### Scenario: Analyzer reports clean result

- GIVEN the three modified files with changes applied
- WHEN running `flutter analyze`
- THEN the output SHALL end with "No issues found!" and exit code SHALL be 0
- AND at most 1 pre-existing `experimental_member_use` warning MAY remain

### Requirement: Build Integrity

`flutter build apk --debug` MUST succeed after changes are applied.

#### Scenario: Debug APK builds cleanly

- GIVEN the project root with changes applied and Flutter SDK on PATH
- WHEN running `flutter build apk --debug`
- THEN the command SHALL exit with code 0
- AND an APK SHALL exist at `build/app/outputs/flutter-apk/app-debug.apk`
