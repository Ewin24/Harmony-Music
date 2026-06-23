# Home Screen Content Loading

## Purpose

Restore home screen content loading. `loadContentFromNetwork()` crashes with `RangeError` when "Quick picks" is missing from the API response or `getContentRelatedToSong()` returns empty — leaving skeleton loaders forever. This spec defines correct loading, caching, and defensive fallback.

## Requirements

### Requirement: Content Display on Network Data

The system MUST display home screen content (not skeletons) within 5 seconds of first launch when network data is available.

#### Scenario: Fresh install loads content from network

- GIVEN app launched on fresh install with network available
- WHEN user opens Home screen
- THEN content SHALL be visible within 5 seconds (not skeleton)
- AND `isContentFetched` SHALL be `true`

### Requirement: Content Display from Cache

The system MUST display cached home screen content (not skeletons) when the network is unavailable and a local cache exists.

#### Scenario: Offline launch shows cached content

- GIVEN network unavailable and Hive "homeScreenData" cache exists
- WHEN user opens Home screen
- THEN cached content SHALL display (not skeletons)
- AND `networkError` SHALL be `false` when content loads from cache

### Requirement: Guard Against Missing Quick Picks

The system MUST NOT throw `RangeError` when "Quick picks" is absent from the home content list. It SHALL fall through gracefully: skip the quick picks assignment, load middle and fixed content from the remaining list, and set `isContentFetched` to `true`.

#### Scenario: Quick picks missing from API response

- GIVEN the home content API response does NOT include an entry with `title == "Quick picks"`
- WHEN `loadContentFromNetwork()` runs
- THEN no `RangeError` SHALL be thrown at `homeContentListMap.removeAt(index)`
- AND `isContentFetched` SHALL become `true`
- AND middle and fixed content SHALL be populated from available entries

#### Scenario: Quick picks present — normal path unchanged

- GIVEN the home content API response includes "Quick picks" at a valid index
- WHEN `loadContentFromNetwork()` runs
- THEN quick picks SHALL be assigned from the "Quick picks" entry
- AND the entry SHALL be removed from the content map before building middle/fixed lists
- AND behavior SHALL match the pre-fix happy path

### Requirement: Guard Against Empty Related Content

When `getContentRelatedToSong()` returns an empty list (no related content), the system SHALL fall through gracefully — no `RangeError`, and the BOLI content type path SHALL exit without crashing.

#### Scenario: Related content API returns empty

- GIVEN `getContentRelatedToSong(songId, hlCode)` returns an empty list
- WHEN `loadContentFromNetwork()` runs with `contentType == "BOLI"`
- THEN no `RangeError` SHALL be thrown at `rel.removeAt(0)`
- AND the catch block at line 147 SHALL handle the empty state without side effects

### Requirement: Analyze Integrity

`flutter analyze` executed from the project root MUST report zero errors and zero warnings after the defensive guards are applied.

#### Scenario: Analyzer reports no issues

- GIVEN the project root with the quick-picks guard and BOLI guard applied
- WHEN running `flutter analyze`
- THEN output SHALL end with "No issues found!" and exit code SHALL be 0

### Requirement: Build Integrity

`flutter build apk --debug` MUST succeed after the defensive guards are applied.

#### Scenario: Debug APK builds cleanly

- GIVEN the project root with the fixes applied and Flutter SDK on PATH
- WHEN running `flutter build apk --debug`
- THEN command SHALL exit with code 0
- AND an APK SHALL exist at `build/app/outputs/flutter-apk/app-debug.apk`

## Out of Scope

- Refactoring `loadContentFromDb()`
- Refactoring `_setContentList()` null safety
- UI redesign or skeleton state improvements
- The music service API layer
- Changing content type switching logic

## Non-Functional Requirements

| Concern | Requirement |
|---------|-------------|
| **Diff size** | Minimal: `if (index != -1)` guard at line 154 + length guard before `removeAt(0)` at line 142 |
| **Defensive coding** | Follow existing pattern at lines 99–101 (Trending guard) |
| **Happy-path** | No behavior change when API response includes all expected entries |
