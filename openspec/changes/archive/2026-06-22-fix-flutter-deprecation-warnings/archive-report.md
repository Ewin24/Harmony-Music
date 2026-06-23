# SDD Archive Report

**Change**: fix-flutter-deprecation-warnings
**Archived**: 2026-06-22
**Project**: harmony-music

## Summary

Fixed Flutter 3.44+ deprecation warnings across 19 files in `lib/`. Five migration categories applied: ThemeData getter reads → colorScheme (C5), withOpacity → withValues(alpha:) (C1), Color.value → toARGB32() (C2), SystemUiOverlayStyle deprecated boolean removal (C3), ThemeData constructor legacy params → colorScheme (C4).

All 8 requirements verified PASS. No CRITICAL issues.

## Artifacts

- `openspec/changes/archive/2026-06-22-fix-flutter-deprecation-warnings/proposal.md`
- `openspec/changes/archive/2026-06-22-fix-flutter-deprecation-warnings/specs/deprecation-cleanup/spec.md`
- `openspec/changes/archive/2026-06-22-fix-flutter-deprecation-warnings/design.md`
- `openspec/changes/archive/2026-06-22-fix-flutter-deprecation-warnings/tasks.md`
- `openspec/changes/archive/2026-06-22-fix-flutter-deprecation-warnings/verify-report.md`
- `openspec/changes/archive/2026-06-22-fix-flutter-deprecation-warnings/archive-report.md`

## Commits Made

1. `b7af188` - refactor(theme): migrate ThemeData getter reads to colorScheme
2. `2064daa` - refactor: replace withOpacity with withValues(alpha:)
3. `43bcead` - refactor: use toARGB32() instead of Color.value
4. `384d6ff` - refactor: remove deprecated SystemUiOverlayStyle boolean properties
5. `097622f` - refactor(theme): migrate ThemeData constructor to colorScheme
6. `eec7c1d` - fix: use const for SystemUiOverlayStyle() calls

## Files Changed (19 lib/*.dart files)

- `lib/ui/utils/theme_controller.dart` — C2, C3, C4, C5
- `lib/ui/home.dart` — C1, C5
- `lib/ui/player/player.dart` — C1
- `lib/ui/player/components/albumart_lyrics.dart` — C1
- `lib/ui/player/components/gesture_player.dart` — C1
- `lib/ui/player/components/mini_player.dart` — C1
- `lib/ui/player/components/player_control.dart` — C1
- `lib/ui/player/components/standard_player.dart` — C1
- `lib/ui/widgets/cust_switch.dart` — C1
- `lib/ui/widgets/playlist_export_dialog.dart` — C1, C5
- `lib/ui/widgets/sliding_up_panel.dart` — C1
- `lib/ui/widgets/up_next_queue.dart` — C1
- `lib/ui/screens/Album/album_screen.dart` — C5
- `lib/ui/screens/Artists/artist_screen_v2.dart` — C5
- `lib/ui/screens/Home/home_screen.dart` — C5
- `lib/ui/screens/Library/library_combined.dart` — C5
- `lib/ui/screens/Library/library_controller.dart` — C5
- `lib/ui/screens/Playlist/playlist_screen.dart` — C5
- `lib/ui/screens/Playlist/playlist_screen_controller.dart` — C5
- `lib/ui/screens/Settings/settings_screen.dart` — C5
- `lib/ui/widgets/add_to_playlist.dart` — C5
- `lib/ui/widgets/backup_dialog.dart` — C5
- `lib/ui/widgets/content_list_widget_item.dart` — C5
- `lib/ui/widgets/create_playlist_dialog.dart` — C5
- `lib/ui/widgets/custom_button.dart` — C5
- `lib/ui/widgets/export_file_dialog.dart` — C5
- `lib/ui/widgets/link_piped.dart` — C5
- `lib/ui/widgets/new_version_dialog.dart` — C5
- `lib/ui/widgets/restore_dialog.dart` — C5
- `lib/ui/widgets/sort_widget.dart` — C5

## Verification Verdict

**PASS** — 8/8 requirements satisfied. No CRITICAL or WARNING findings.

## Specs Synced

| Domain | Action | Details |
|--------|--------|---------|
| deprecation-cleanup | Created | 8 requirements, 8 scenarios — converted from delta to main spec |

## Follow-ups

- 3 commented-out references to deprecated theme properties in unrelated files (harmless, can clean up opportunistically)
- 29 pre-existing analyzer infos remain (Color channel accessors, Radio, ReorderableListView, activeColor) — out of scope per spec

## SDD Cycle Complete

The change has been fully planned, implemented, verified, and archived.
