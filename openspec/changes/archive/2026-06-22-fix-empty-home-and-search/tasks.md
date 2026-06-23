# Tasks: Fix empty home and empty search results

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~15-20 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR (2 commits) |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Fix home crash + fix search rendering | PR 1 | Single PR, 2 commits. Both fixes isolated, independent, trivially reviewable at ~15-20 lines total. |

## Phase 1: Fix Home Screen Crash

- [x] 1.1 Add `if (rel.isNotEmpty)` guard before `rel.removeAt(0)` at line 142 in `lib/ui/screens/Home/home_screen_controller.dart` — prevents RangeError when `getContentRelatedToSong()` returns empty list
- [x] 1.2 Add `if (index != -1)` guard before `homeContentListMap.removeAt(index)` at line 156 in `lib/ui/screens/Home/home_screen_controller.dart` — prevents RangeError when "Quick picks" is missing from API response
- **Done when**: hot reload shows home content (not skeleton loaders); no RangeError in logcat
- **Files touched**: `lib/ui/screens/Home/home_screen_controller.dart`
- **Estimated lines**: ~5

## Phase 2: Fix Search Results Display

- [x] 2.1 Uncomment `import '/models/playlist.dart';` at line 8 in `lib/ui/widgets/search_related_widgets.dart`
- [x] 2.2 Uncomment the playlist `else if` rendering block (lines 75-83) in `lib/ui/widgets/search_related_widgets.dart` — restores `ContentListWidget` with `PlaylistContent` for keys containing "playlist"
- **Done when**: search results show playlist items in the Results tab (not just songs/albums/artists)
- **Files touched**: `lib/ui/widgets/search_related_widgets.dart`
- **Estimated lines**: ~12

## Phase 3: Final Verification

- [x] 3.1 Run `flutter analyze` — confirm "No issues found!" and exit code 0
- [x] 3.2 Run `flutter build apk --debug` — confirm exit code 0 and APK at `build/app/outputs/flutter-apk/app-debug.apk`
- [x] 3.3 Hot reload app on device/emulator — verify home content loads (not skeletons) within 5s
- [x] 3.4 Perform a search — verify playlists appear in the Results tab alongside songs, albums, artists
- **Done when**: all checks pass; no additional commit required
- **Files touched**: none
- **Estimated lines**: 0

## Implementation Order

1. Fix home guard (Phase 1) — no dependencies
2. Fix search rendering (Phase 2) — verify build still clean after Phase 1
3. Final verification (Phase 3) — depends on both fixes applied
