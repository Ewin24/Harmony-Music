# Changelog

All notable changes to Harmony-Music are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.12.2] - 2026-06-25

### Fixed
- **Search main view now shows previews** instead of empty "view all" sections.
  Root cause: YouTube Music changed `sectionListRenderer.contents` from
  category-grouped shelves to a flat list of individually-wrapped items.
  The bucketing loop now extracts each `musicResponsiveListItemRenderer`,
  classifies it by `pageType`, and places it in the right bucket
  ("Songs", "Artists", "Albums", "Featured playlists", etc.).
- **Crashes in community-playlist search** (`type 'Album' is not a
  subtype of type 'Playlist?'`) fixed by switching `parseSearchResult`
  to use the canonical `pageType` signal instead of the unreliable
  `flexColumns[1].runs[0].text` (which for playlists is the author
  name, not the item type).
- **Empty "Community playlists" section** in the main view removed;
  the category is still accessible via the rail tab.

### Added
- **ResponseRecorder utility** (`lib/utils/response_recorder.dart`):
  persists raw API request/response pairs to disk for offline analysis.
  Enable with `--dart-define=RECORD_API=true`. Accessible via `adb pull`
  without `run-as` and without stopping the app.
- **Compact HTTP logger**: emits one-line summaries (status, time, size,
  top-level keys) to the console; full bodies go to the recorder file
  instead of flooding logcat.
- **API surface documentation** in `docs/api/`:
  - Postman collection for all 8 endpoints
  - `API-SURFACE.md` documenting the `params` filter token system
  - `RECORDER.md` with `adb pull` commands
  - `ALTERNATIVES.md` evaluating 7 migration paths if YouTube Music
    becomes too unreliable
- **Defensive widget cast** in the search main view: skips buckets
  with wrong item type or empty content instead of crashing.

## [1.12.1] - 2026-06-15

### Fixed
- QuickPicksWidget collapsed when empty to avoid extra height.
- `removeAt(-1)` RangeError on Home guarded.

## [1.12.0] - 2026-06-10

### Added
- Home enriched with 9 default sections and reduced gap.

[1.12.2]: https://github.com/Ewin24/Harmony-Music/releases/tag/v1.12.2
[1.12.1]: https://github.com/Ewin24/Harmony-Music/releases/tag/v1.12.1
[1.12.0]: https://github.com/Ewin24/Harmony-Music/releases/tag/v1.12.0
