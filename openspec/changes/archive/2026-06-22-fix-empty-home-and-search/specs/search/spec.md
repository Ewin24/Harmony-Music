# Search Results Display

## Purpose

Restore playlist visibility in the search Results tab. Currently, `ResultWidget.generateWidgetList()` skips playlists because the playlist rendering block and `Playlist` model import are commented out. This spec defines correct display of all result categories (songs, albums, artists, playlists, community playlists) in the initial Results tab.

## Requirements

### Requirement: All Result Types Displayed

The search Results tab MUST display all result categories returned by the API: songs, albums, artists, and playlists (including community playlists).

#### Scenario: Search displays all result categories

- GIVEN a user has searched for a term and the API returns songs, albums, artists, and playlists
- WHEN the user is on the Results tab
- THEN songs and albums SHALL render as `SeparateTabItemWidget` or `ContentListWidget`
- AND playlists SHALL render as `ContentListWidget` with `PlaylistContent` for keys containing "playlist"
- AND artists SHALL render as `SeparateTabItemWidget`

#### Scenario: Quick picks entry only — artists still shown

- GIVEN the result content map contains only a single non-playlist entry
- WHEN `generateWidgetList()` iterates the map entries
- THEN the entry SHALL match its category handler and render correctly
- AND no entry SHALL be silently skipped due to the playlist block being commented out

### Requirement: Playlist Import Restored

The file `search_related_widgets.dart` MUST import `Playlist` from `package:harmony_music/models/playlist.dart` so that `PlaylistContent` is resolvable at compile time.

#### Scenario: Playlist import is active

- GIVEN `lib/ui/widgets/search_related_widgets.dart`
- WHEN reading the imports section
- THEN `import '/models/playlist.dart';` SHALL be present and uncommented

### Requirement: Analyze Integrity

`flutter analyze` executed from the project root MUST report zero errors and zero warnings after the import and rendering block are restored.

#### Scenario: Analyzer reports no issues

- GIVEN the playlist import is active and the rendering block is uncommented
- WHEN running `flutter analyze`
- THEN output SHALL end with "No issues found!" and exit code SHALL be 0

### Requirement: Build Integrity

`flutter build apk --debug` MUST succeed after the playlist rendering is restored.

#### Scenario: Debug APK builds cleanly

- GIVEN the playlist import and rendering block are active and Flutter SDK is on PATH
- WHEN running `flutter build apk --debug`
- THEN command SHALL exit with code 0
- AND an APK SHALL exist at `build/app/outputs/flutter-apk/app-debug.apk`

## Out of Scope

- Refactoring the search controller
- Adding new result categories beyond those already in the API response
- Changing the search endpoint or recommendation layer
- UI redesign of the Results tab layout

## Non-Functional Requirements

| Concern | Requirement |
|---------|-------------|
| **Diff size** | The change SHALL be limited to two lines in `search_related_widgets.dart`: uncommenting `import '/models/playlist.dart';` (line 8) and uncommenting the playlist `else if` block (lines 75–83) |
| **Defensive coding** | The playlist category check SHALL use `.contains("playlist")` (existing pattern) to match both "Community playlists" and "Featured playlists" |
| **Happy-path preservation** | Non-playlist rendering (songs, albums, artists) SHALL NOT change; only the previously commented-out playlist block is restored |
