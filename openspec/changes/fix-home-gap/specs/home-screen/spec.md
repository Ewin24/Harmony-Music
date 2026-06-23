# Delta for home-screen

## ADDED Requirements

### Requirement: QuickPicksWidget Collapses on Empty SongList

The system SHALL render QuickPicksWidget with zero height when its `songList` is empty.

#### Scenario: Empty list renders no space

- GIVEN QuickPicksWidget receives an empty `songList`
- WHEN the widget builds
- THEN it SHALL return `const SizedBox.shrink()`
- AND no blank 340px block SHALL appear in the home screen layout

### Requirement: QuickPicksWidget Sizes to Content

When `songList` contains items, QuickPicksWidget SHALL occupy only the vertical space its grid requires — not a fixed 340px minimum.

#### Scenario: Content-driven height

- GIVEN QuickPicksWidget with N items in `songList`
- WHEN the widget builds
- THEN its height SHALL be derived from grid rows × item height + spacing
- AND no `SizedBox(height: 340)` or `Expanded` SHALL stretch empty grid space

#### Scenario: Eight songs fill grid without blank rows

- GIVEN QuickPicksWidget with 8 songs in `songList`
- WHEN the widget renders
- THEN the grid SHALL display 4 rows × 2 columns of items
- AND no blank rows SHALL appear below the last row

### Requirement: Bounded Gap Below QuickPicks

The home screen SHALL NOT exhibit a vertical gap larger than 30px between the QuickPicksWidget bottom edge and the next content section.

#### Scenario: Gap within tolerance

- GIVEN the home screen with QuickPicks and the next section visible
- WHEN the user scrolls past QuickPicks
- THEN no visible gap larger than 30px SHALL exist before the next section

### Requirement: Adaptive-Sizing Analyze Integrity

`flutter analyze` executed from the project root SHALL report zero errors and zero warnings after the adaptive-sizing changes are applied.

#### Scenario: Analyzer passes

- GIVEN the project root with the adaptive-sizing fix applied
- WHEN running `flutter analyze`
- THEN output SHALL end with "No issues found!" and exit code SHALL be 0

### Requirement: Adaptive-Sizing Build Integrity

`flutter build apk --debug` executed from the project root SHALL succeed after the adaptive-sizing changes are applied.

#### Scenario: Debug APK builds

- GIVEN the project root with the adaptive-sizing fix applied
- WHEN running `flutter build apk --debug`
- THEN the command SHALL exit with code 0
- AND an APK SHALL exist at `build/app/outputs/flutter-apk/app-debug.apk`
