# Archive Report: fix-remaining-deprecations

**Change**: Fix Remaining Flutter Deprecation Infos
**Date**: 2026-06-22
**Archive path**: `openspec/changes/archive/2026-06-22-fix-remaining-deprecations/`
**Project**: harmony-music
**Verdict**: PASS

---

## Summary

This change cleaned the last 29 info-level deprecation notices from `flutter analyze` across 6 migration categories. It extends the previous `fix-flutter-deprecation-warnings` change, which resolved errors+warnings, to now cover info-level deprecations. All 8 requirements verified PASS. Specs have been merged into the source-of-truth `openspec/specs/deprecation-cleanup/spec.md`.

## Specs Synced

| Domain | Action | Details |
|--------|--------|---------|
| deprecation-cleanup | Updated | 6 ADDED requirements appended (R1–R6), preserving all 8 existing requirements. R7 (Zero-Analyze) and R8 (Build Integrity) excluded as already covered by existing requirements. |

### Added Requirements

1. **Color Channel Accessor Migration** — `Color.red/green/blue/alpha` → `channelRed/Green/Blue/Alpha`
2. **Radio → RadioGroup\<T\> Migration** — Deprecated `groupValue`+`onChanged` on Radio → RadioGroup wrapper
3. **ReorderableListView onReorder → onReorderItem** — Rename + remove index compensation
4. **Switch.activeColor → WidgetStateProperty fillColor** — WidgetStateProperty.resolveWith pattern
5. **ThemeData.indicatorColor → TabBarThemeData.indicatorColor** — Move to sub-theme
6. **Theme.of(context).primaryColor → colorScheme.primary** — 9 files, ~19 occurrences

## Archive Contents

| Artifact | Status |
|----------|--------|
| proposal.md | ✅ |
| specs/deprecation-cleanup/spec.md | ✅ |
| design.md | ✅ |
| tasks.md | ✅ (13/13 tasks complete) |
| verify-report.md | ✅ |

## Commits

| SHA | Message |
|-----|---------|
| 6ac73b6 | refactor: migrate color channel int accessors to channel* API |
| e2a57e4 | refactor: migrate Switch.activeColor to WidgetStateProperty |
| 5cecd10 | refactor: migrate ThemeData.indicatorColor to TabBarThemeData |
| f939127 | refactor: migrate ReorderableListView onReorder to onReorderItem |
| e8e4bb6 | refactor: migrate Radio groupValue/onChanged to RadioGroup\<T\> wrapper |
| d7c6dc9 | refactor: replace Theme.of(context).primaryColor with colorScheme.primary |

## Files Changed (15 source files)

- `lib/ui/utils/theme_controller.dart` (R1, R5)
- `lib/ui/widgets/cust_switch.dart` (R4, R6)
- `lib/ui/widgets/modification_list.dart` (R3)
- `lib/ui/widgets/up_next_queue.dart` (R3)
- `lib/ui/widgets/add_to_playlist.dart` (R2)
- `lib/ui/widgets/create_playlist_dialog.dart` (R2)
- `lib/ui/screens/Settings/settings_screen.dart` (R2)
- `lib/ui/player/player.dart` (R6)
- `lib/ui/widgets/bottom_nav_bar.dart` (R6)
- `lib/ui/player/components/lyrics_switch.dart` (R6)
- `lib/ui/player/components/standard_player.dart` (R6)
- `lib/ui/player/components/gesture_player.dart` (R6)
- `lib/ui/player/components/albumart_lyrics.dart` (R6)
- `lib/ui/screens/Search/search_result_screen_v2.dart` (R6)
- `lib/ui/widgets/side_nav_bar.dart` (R6)

## Verification Results

| ID | Requirement | Status |
|----|-------------|--------|
| R1 | Color channel accessors | PASS |
| R2 | Radio → RadioGroup\<T\> | PASS |
| R3 | ReorderableListView onReorder → onReorderItem | PASS |
| R4 | Switch.activeColor → WidgetStateProperty | PASS |
| R5 | ThemeData.indicatorColor → TabBarThemeData | PASS |
| R6 | Theme.of(context).primaryColor → colorScheme.primary | PASS |
| R7 | flutter analyze — zero deprecation infos | PASS |
| R8 | flutter build apk --debug succeeds | PASS |

## Deviations from Spec

- **R1 implementation**: Spec proposed `channelRed/Green/Blue/Alpha` API which doesn't exist in Flutter 3.44.2. Apply used `(color.r * 255.0).round().clamp(0, 255)` formula instead — functionally equivalent.
- **R4 implementation**: Used `thumbColor: WidgetStateProperty.all(Colors.white)` instead of `fillColor` — simpler API, same visual result.

## Follow-ups

1. **Spec correction**: Update R1 spec to document actual formula `(color.r * 255.0).round().clamp(0, 255)` instead of `channel*` API.
2. **Pre-existing warning**: `experimental_member_use` in `lib/services/audio_handler.dart` is unrelated but should be tracked.
3. **Build infra**: Gradle 8.9.0, AGP 8.6.0, and Kotlin 2.1.0 nearing end of Flutter support.

## Engram Observations

- `sdd/fix-remaining-deprecations/apply-progress` → ID #516
- `sdd/fix-remaining-deprecations/verify-report` → ID #517
- `sdd/fix-remaining-deprecations/archive-report` → (this report)

## Source of Truth Updated

`openspec/specs/deprecation-cleanup/spec.md` now reflects all deprecation cleanup requirements from both changes (14 requirements total, 8 original + 6 added).

---

**SDD Cycle Complete**. Change fully planned, implemented, verified, and archived.
