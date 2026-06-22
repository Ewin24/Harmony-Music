# Design: Fix Flutter 3.44+ Deprecation Warnings

## Technical Approach

Pure refactor — zero architectural change. Five independent mechanical migration categories applied as a **transformation pipeline**:
each category is a self-contained commit that replaces one deprecated API pattern across the entire `lib/` tree.

```
lib/ (current, ~84 deprecation warnings)
  ├── C5: ThemeData getter reads → colorScheme.*      [~28 lines, 15 files]
  ├── C1: withOpacity(x) → withValues(alpha: x)        [29 lines, 12 files]
  ├── C2: Color.value → toARGB32()                     [2 lines, 1 file]
  ├── C3: SystemUiOverlayStyle deprecated booleans      [21 lines, 1 file]
  └── C4: ThemeData() legacy props → colorScheme        [~23 lines, 1 file]
```

**Order rationale**: C5 first — most files, purely mechanical, catches any missed visual effects early. C1 second — also widespread, same reasoning. C2–C4 last — limited to `theme_controller.dart`, can be reviewed together or separately.

## Migration Matrix

| Cat | Pattern | Replacement | Occurrences | Files | Risk |
|-----|---------|-------------|-------------|-------|------|
| C1 | `.withOpacity(x)` | `.withValues(alpha: x)` | 29 | 12 | Low |
| C2 | `Color.value` | `.toARGB32()` | 2 | 1 | Low |
| C3 | `SystemUiOverlayStyle` booleans | Remove deprecated props | 21 (7×3) | 1 | Low |
| C4 | `ThemeData(...)` deprecated params | `colorScheme: ColorScheme.fromSwatch(...).copyWith(...)` | ~23 | 1 | Medium |
| C5 | `Theme.of(context).canvasColor` etc. | `Theme.of(context).colorScheme.surface` etc. | ~28 | ~15 | Medium |

### Mapping Tables

**C5 — deprecated getter → colorScheme property**:

| Deprecated Getter | Replacement | Occurrences |
|-------------------|-------------|-------------|
| `canvasColor` | `colorScheme.surface` | 13 |
| `cardColor` | `colorScheme.surfaceContainerHigh` | 7 |
| `primaryColorLight` | `colorScheme.primaryContainer` | 2 |
| `scaffoldBackgroundColor` | `colorScheme.surface` | 3 active |
| `dividerColor` | `colorScheme.outlineVariant` | 3 |

**C4 — ThemeData() deprecated param → colorScheme migration**:

Each `ColorScheme.fromSwatch(...)` call gains a `.copyWith(...)` for properties that don't map directly. The `useMaterial3: false` is preserved (out of scope).

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/ui/utils/theme_controller.dart` | Modify | C2, C3, C4, + C5 scaffoldBackgroundColor reads |
| `lib/ui/home.dart` | Modify | C1 (1), C5 canvasColor (1) |
| `lib/ui/player/player.dart` | Modify | C1 (4) |
| `lib/ui/player/components/albumart_lyrics.dart` | Modify | C1 (3) |
| `lib/ui/player/components/gesture_player.dart` | Modify | C1 (3) |
| `lib/ui/player/components/mini_player.dart` | Modify | C1 (3) |
| `lib/ui/player/components/player_control.dart` | Modify | C1 (3) |
| `lib/ui/player/components/standard_player.dart` | Modify | C1 (3) |
| `lib/ui/widgets/cust_switch.dart` | Modify | C1 (1) |
| `lib/ui/widgets/playlist_export_dialog.dart` | Modify | C1 (3) + C5 cardColor (2) + dividerColor (3) |
| `lib/ui/widgets/sliding_up_panel.dart` | Modify | C1 (1) |
| `lib/ui/widgets/up_next_queue.dart` | Modify | C1 (1) |
| `lib/ui/screens/Album/album_screen.dart` | Modify | C5 canvasColor (2) |
| `lib/ui/screens/Artists/artist_screen_v2.dart` | Modify | C5 canvasColor (1) |
| `lib/ui/screens/Home/home_screen.dart` | Modify | C5 canvasColor (1) |
| `lib/ui/screens/Library/library_combined.dart` | Modify | C5 canvasColor (1) |
| `lib/ui/screens/Library/library_controller.dart` | Modify | C5 cardColor (1) |
| `lib/ui/screens/Playlist/playlist_screen.dart` | Modify | C5 canvasColor (2) |
| `lib/ui/screens/Playlist/playlist_screen_controller.dart` | Modify | C5 cardColor (1) |
| `lib/ui/screens/Settings/settings_screen.dart` | Modify | C5 cardColor (5 active) |
| `lib/ui/screens/Search/search_result_screen_v2.dart` | No change | Already uses `colorScheme.secondary` — clean |
| `lib/ui/widgets/add_to_playlist.dart` | Modify | C5 primaryColorLight (1) |
| `lib/ui/widgets/backup_dialog.dart` | Modify | C5 canvasColor (1) |
| `lib/ui/widgets/content_list_widget_item.dart` | Modify | C5 primaryColorLight (1) |
| `lib/ui/widgets/create_playlist_dialog.dart` | Modify | C5 canvasColor (1) |
| `lib/ui/widgets/custom_button.dart` | Modify | C5 canvasColor (1) |
| `lib/ui/widgets/export_file_dialog.dart` | Modify | C5 canvasColor (1) |
| `lib/ui/widgets/link_piped.dart` | Modify | C5 canvasColor (1) |
| `lib/ui/widgets/new_version_dialog.dart` | Modify | C5 canvasColor (1) |
| `lib/ui/widgets/restore_dialog.dart` | Modify | C5 canvasColor (1) |
| `lib/ui/widgets/sort_widget.dart` | Modify | C5 cardColor (1) + scaffoldBackgroundColor (1) |
| `test/widget_test.dart` | No change | Default counter test, no deprecated APIs used |

## Interfaces / Contracts

No new interfaces. All replacements are one-to-one API substitutions producing identical values:

- `withOpacity(x)` → `withValues(alpha: x)` — same 0.0–1.0 range, same `Color` return type
- `Color.value` → `Color.toARGB32()` — same `int` return type
- `SystemUiOverlayStyle` property removal — defaults replace removed values
- ThemeData getter → `colorScheme.*` — verify mapping table above

## Edge Cases & Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| `.value` on non-Color objects | Low | Only 2 call sites in theme_controller.dart — both on `Color`-typed variables |
| `canvasColor` → `surface` changes background tint on some screens | Medium | Each canvasColor read maps to `colorScheme.surface`. For surfaces where a distinct canvas color was intended, use `surfaceContainerLow`. Verify visually post-apply. |
| `cardColor` → `surfaceContainerHigh` may differ from `primarySwatch[600]` | Medium | The dynamic theme sets `cardColor: primarySwatch[600]` explicitly — colorScheme may derive differently. Keep the `copyWith(surfaceContainerHigh: primarySwatch[600])` for the dynamic theme branch. |
| `MaterialColor(color.value, swatch)` in `_createMaterialColor` | Low | `color.toARGB32()` returns same int. Verified same semantics. |
| `test/widget_test.dart` already broken | None | Pre-existing — imports `MyApp` correctly but tests counter logic that doesn't exist. Out of scope for this change. |

## Commit Strategy

| Commit | Category | Change Scope | Estimated Lines |
|--------|----------|--------------|-----------------|
| 1 | C5 — ThemeData getter reads | ~15 files | ~28 |
| 2 | C1 — withOpacity | 12 files | 29 |
| 3 | C2 — Color.value | 1 file, 2 lines | 2 |
| 4 | C3 — SystemUiOverlayStyle | 1 file, 21 lines | 21 |
| 5 | C4 — ThemeData constructor | 1 file, ~23 lines | ~23 |

Each commit must compile independently (`dart analyze` passes per commit).

## Verification

1. After each category commit: `dart analyze lib/` — zero errors
2. After all commits: `dart analyze` (full project) — "No issues found!"
3. `grep -r "withOpacity(" lib/` — zero matches
4. `grep -r "\.scaffoldBackgroundColor" lib/` — zero active matches (only comments)
5. `flutter build apk --debug` — builds successfully
6. Visual smoke check: launch APK on light + dark themes, verify no color regressions

## Backout Plan

Each category is an independent commit → `git revert <commit-sha>` per category. No cross-category dependencies. Full visual baseline captured via git diff before C4/C5 application for rollback reference.

## Open Questions

- [ ] C5: `cardColor` → `surfaceContainerHigh` or `surfaceContainerLow`? Proposal uses `surfaceContainerHigh`. Verify on settings dropdowns which use `cardColor` as `dropdownColor`.
- [ ] C4: Some `ColorScheme.fromSwatch()` params are also deprecated (`accentColor`, `backgroundColor`, `cardColor`). Should these migrate to `ColorScheme.fromSeed(...)` entirely? (Deferred — out of scope per spec).
