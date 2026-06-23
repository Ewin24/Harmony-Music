# Tasks: Fix Flutter 3.44+ Deprecation Warnings

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~103 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR (5 commits) |
| Delivery strategy | ask-always |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | ThemeData getter reads → colorScheme (C5) | Commit 1 of 1 PR | 15 files, ~28 lines, base = main |
| 2 | withOpacity → withValues (C1) | Commit 2 of 1 PR | 12 files, 29 lines |
| 3 | Color.value → toARGB32 (C2) | Commit 3 of 1 PR | 1 file, 2 lines |
| 4 | SystemUiOverlayStyle cleanup (C3) | Commit 4 of 1 PR | 1 file, 21 lines |
| 5 | ThemeData constructor → colorScheme (C4) | Commit 5 of 1 PR | 1 file, ~23 lines |
| 6 | Final verification | Commit 6 of 1 PR | No code changes |

## Phase 1: ThemeData Getter Reads → colorScheme (C5)

- [x] 1.1 Migrate `Theme.of(context).canvasColor` → `Theme.of(context).colorScheme.surface` in all files (album_screen, artist_screen_v2, home_screen, library_combined, playlist_screen, backup_dialog, create_playlist_dialog, custom_button, export_file_dialog, link_piped, new_version_dialog, restore_dialog, home.dart)
- [x] 1.2 Migrate `Theme.of(context).cardColor` → `Theme.of(context).colorScheme.surfaceContainerHigh` (library_controller, playlist_screen_controller, settings_screen, sort_widget, playlist_export_dialog)
- [x] 1.3 Migrate `Theme.of(context).primaryColorLight` → `Theme.of(context).colorScheme.primaryContainer` (add_to_playlist, content_list_widget_item)
- [x] 1.4 Migrate `Theme.of(context).scaffoldBackgroundColor` → `Theme.of(context).colorScheme.surface` (theme_controller, sort_widget)
- [x] 1.5 Migrate `Theme.of(context).dividerColor` → `Theme.of(context).colorScheme.outlineVariant` (playlist_export_dialog)
- **Done when**: `grep` for deprecated ThemeData getter reads returns 0 matches in `lib/`
- **Files touched**: ~21 files (screens, widgets, theme_controller)
- **Estimated lines**: ~28
- **Commit message**: `refactor(theme): migrate ThemeData getter reads to colorScheme`
- **Depends on**: nothing (first commit)

## Phase 2: withOpacity → withValues(alpha:) (C1)

- [x] 2.1 Replace `Colors.white.withOpacity(x)` → `Colors.white.withValues(alpha: x)` across all files
- [x] 2.2 Replace all other `.withOpacity(x)` calls → `.withValues(alpha: x)` preserving the same numeric argument
- **Done when**: `grep "withOpacity(" lib/` returns 0 matches
- **Files touched**: player.dart, albumart_lyrics.dart, gesture_player.dart, mini_player.dart, standard_player.dart, player_control.dart, home.dart, theme_controller.dart, playlist_export_dialog.dart, cust_switch.dart, sliding_up_panel.dart, up_next_queue.dart
- **Estimated lines**: 29
- **Commit message**: `refactor: replace withOpacity with withValues(alpha:)`
- **Depends on**: Phase 1 (same file overlap → sequential to avoid conflicts)

## Phase 3: Color.value → toARGB32 (C2)

- [x] 3.1 Replace `color.value` → `color.toARGB32()` in theme_controller.dart `_createMaterialColor`
- [x] 3.2 Verify no other `Color.value` calls exist in that file (exclude non-Color `.value` accesses)
- **Done when**: `grep` for `.value` on Color objects in `lib/ui/utils/theme_controller.dart` returns 0 matches
- **Files touched**: `lib/ui/utils/theme_controller.dart` (1 file)
- **Estimated lines**: 2
- **Commit message**: `refactor: use toARGB32() instead of Color.value`
- **Depends on**: Phase 2 (same file → sequential)

## Phase 4: Remove SystemUiOverlayStyle Deprecated Booleans (C3)

- [x] 4.1 Remove `statusBarColor` parameter from all 3 `SystemUiOverlayStyle()` calls in theme_controller.dart
- [x] 4.2 Remove `statusBarIconBrightness` parameter from all 3 calls
- [x] 4.3 Remove `statusBarBrightness` parameter from all 3 calls
- [x] 4.4 Remove `systemNavigationBarColor` parameter from all 3 calls
- [x] 4.5 Remove `systemNavigationBarDividerColor` parameter from all 3 calls
- [x] 4.6 Remove `systemNavigationBarIconBrightness` parameter from all 3 calls
- [x] 4.7 Remove `systemStatusBarContrastEnforced` from all 3 calls
- [x] 4.8 Remove `systemNavigationBarContrastEnforced` from all 3 calls
- **Done when**: grep for any of the 8 deprecated boolean property names returns 0 matches in `lib/`
- **Files touched**: `lib/ui/utils/theme_controller.dart` (1 file)
- **Estimated lines**: 21
- **Commit message**: `refactor: remove deprecated SystemUiOverlayStyle boolean properties`
- **Depends on**: Phase 3 (same file → sequential)

## Phase 5: ThemeData Constructor Legacy Params → colorScheme (C4)

- [x] 5.1 Remove `accentColor` from ThemeData() constructor calls (3 occurrences)
- [x] 5.2 Remove `canvasColor` from ThemeData() constructor calls (3 occurrences)
- [x] 5.3 Remove `cardColor` from ThemeData() constructor calls (2 occurrences)
- [x] 5.4 Remove `dialogBackgroundColor` from ThemeData() constructor calls (1 occurrence)
- [x] 5.5 Remove `primaryColorLight` from ThemeData() constructor calls (3 occurrences)
- [x] 5.6 Remove `primaryColorDark` from ThemeData() constructor calls (2 occurrences)
- [x] 5.7 Remove `backgroundColor` from ThemeData() constructor calls (3 occurrences)
- [x] 5.8 Replace with `ColorScheme.fromSwatch(...).copyWith(...)` mapping each removed param to the appropriate colorScheme property
- [x] 5.9 Preserve `useMaterial3: false` (out of scope to switch to MD3)
- **Done when**: grep for deprecated ThemeData constructor params returns 0 matches in `lib/`
- **Files touched**: `lib/ui/utils/theme_controller.dart` (1 file)
- **Estimated lines**: ~23
- **Commit message**: `refactor(theme): migrate ThemeData constructor to colorScheme`
- **Depends on**: Phase 4 (same file → sequential)

## Phase 6: Final Verification

- [x] 6.1 Run `dart analyze lib/` after each commit to confirm zero errors
- [x] 6.2 Run `grep -r "withOpacity(" lib/` — confirm 0 matches
- [x] 6.3 Run `grep -r "\.canvasColor" lib/` — confirm 0 matches (comments excluded)
- [x] 6.4 Run `grep -r "\.scaffoldBackgroundColor" lib/` — confirm 0 active matches
- [x] 6.5 Run `flutter analyze` from project root — confirm zero errors, zero deprecation issues from the 5 migration categories
- [x] 6.6 Run `flutter build apk --debug` — confirm builds successfully
- **Done when**: `flutter analyze` is clean, `flutter build apk --debug` succeeds, all grep sweeps return 0
- **Files touched**: none
- **Estimated lines**: 0
- **Commit message**: N/A (verification only, no commit)
- **Depends on**: Phase 5 (all fixes applied)

## Summary

| Phase | Tasks | Focus |
|-------|-------|-------|
| Phase 1 (C5) | 5 | ThemeData getter reads → colorScheme |
| Phase 2 (C1) | 2 | withOpacity → withValues(alpha:) |
| Phase 3 (C2) | 2 | Color.value → toARGB32 |
| Phase 4 (C3) | 8 | SystemUiOverlayStyle deprecated booleans |
| Phase 5 (C4) | 9 | ThemeData constructor → colorScheme |
| Phase 6 | 6 | Final verification |
| **Total** | **32** | |
