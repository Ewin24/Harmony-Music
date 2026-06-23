# Design: Fix Remaining Flutter Deprecation Infos

## Technical Approach

Pure mechanical refactor across 6 deprecation categories (~60-70 lines, ~9 files). Each category is a single, revertible commit verified by `flutter analyze` before moving to the next. Order: R1 (color channels, mechanical) → R3/R4/R5 (single-file, low risk) → R2 (Radio, widget tree) → R6 (primaryColor, cross-file getter cleanup).

## Architecture Decisions

| Option | Tradeoff | Decision |
|--------|----------|----------|
| `color.r` → `color.channelRed` vs `color.r` (double) | `channelRed` keeps int 0-255 semantics; `r` changes to double 0-1 requiring arithmetic change | Use `channel*` — zero behavioral change |
| RadioGroup wrapper scope | Minimal: wrap only Radio siblings vs restructure ListTile tree | Use InheritedWidget nature of RadioGroup — wrap parent Column, remove `groupValue`/`onChanged` from each Radio, keep `ListTile` structure |
| `onReorderItem` index removal | `modification_list.dart` has `newIndex--` workaround; `up_next_queue.dart` does NOT | Only remove workaround in `modification_list.dart` |
| `primaryColor` → `colorScheme.primary` | Identical value in this codebase (single-color swatch theme, no MD3) | Direct replacement; no need for `primaryContainer` variants |
| `activeColor` → `fillColor` | `fillColor` requires `WidgetStateProperty`; `thumbColor` is simpler API | Use `thumbColor: WidgetStateProperty.all(Colors.white)` — same visual target, fewer states |

## Migration Matrix

| # | Category | Files | Lines | Pattern | Risk |
|---|----------|-------|-------|---------|------|
| R1 | Color channels | `theme_controller.dart` | 10 | `color.red` → `color.channelRed` (4× int getters) | Low |
| R2 | Radio → RadioGroup | `add_to_playlist.dart`, `create_playlist_dialog.dart`, `settings_screen.dart` | ~30-40 | Wrap sibling Radios in `RadioGroup<T>`, hoist `groupValue`/`onChanged` | Medium |
| R3 | ReorderableListView | `modification_list.dart`, `up_next_queue.dart` | 4 | Rename `onReorder:` → `onReorderItem:`, remove `newIndex--` in mod_list only | Low |
| R4 | Switch.activeColor | `cust_switch.dart` | 2 | `activeColor: Colors.white` → `thumbColor: WidgetStateProperty.all(Colors.white)` | Low |
| R5 | indicatorColor | `theme_controller.dart` | 3 | Move `indicatorColor` from `ThemeData()` into `tabBarTheme: TabBarThemeData(...)` | Low |
| R6 | primaryColor getters | 8 files, 18+ occurrences | ~18 | `Theme.of(context).primaryColor` → `colorScheme.primary` | Low |
| R7 | flutter analyze | — | — | Verification pass | — |
| R8 | build integrity | — | — | `flutter build apk --debug` | — |

**Note**: The grep reveals ~18 `Theme.of(context).primaryColor` occurrences across 8 files (proposal listed 7). `albumart_lyrics.dart` (lines 84, 90) also matches and is included.

## Data Flow

```
Proposal ──→ Spec ──→ Design ──→ Tasks ──→ Apply ──→ Verify
                                                │
                                          flutter analyze
                                          (after each commit)
                                                │
                                          flutter build apk
                                          (final verification)
```

## File Changes

| File | Action | Categories |
|------|--------|------------|
| `lib/ui/utils/theme_controller.dart` | Modify | R1, R5 |
| `lib/ui/widgets/add_to_playlist.dart` | Modify | R2 |
| `lib/ui/widgets/create_playlist_dialog.dart` | Modify | R2 |
| `lib/ui/screens/Settings/settings_screen.dart` | Modify | R2 |
| `lib/ui/widgets/modification_list.dart` | Modify | R3 |
| `lib/ui/widgets/up_next_queue.dart` | Modify | R3 |
| `lib/ui/widgets/cust_switch.dart` | Modify | R4 |
| `lib/ui/player/player.dart` | Modify | R6 |
| `lib/ui/widgets/bottom_nav_bar.dart` | Modify | R6 |
| `lib/ui/player/components/standard_player.dart` | Modify | R6 |
| `lib/ui/player/components/lyrics_switch.dart` | Modify | R6 |
| `lib/ui/player/components/gesture_player.dart` | Modify | R6 |
| `lib/ui/player/components/albumart_lyrics.dart` | Modify | R6 |
| `lib/ui/screens/Search/search_result_screen_v2.dart` | Modify | R6 |
| `lib/ui/widgets/side_nav_bar.dart` | Modify | R6 |

## Key Implementation Notes

### R2 (Radio → RadioGroup)

The `RadioGroup<T>` widget uses InheritedWidget — descendant `Radio<T>` widgets automatically pick up `groupValue` and `onChanged` from the nearest `RadioGroup<T>` ancestor. Strategy:

1. **`add_to_playlist.dart`** (2 Radios, siblings in Row): Wrap the `Row(children: [Radio, SizedBox, Radio])` in `RadioGroup<String>(groupValue: ..., onChanged: ..., child: Row(...))`. Remove `groupValue`/`onChanged` from each `Radio`.

2. **`create_playlist_dialog.dart`** (2 Radios, same pattern): Same approach as above.

3. **`settings_screen.dart`** (2 groups, 8 Radios total):
   - `ThemeSelectorDialog`: 4 `radioWidget(...)` calls with `ThemeType` values inside a `Column`. Wrap the 4 calls in `RadioGroup<ThemeType>(groupValue: controller.themeModetype.value, onChanged: controller.onThemeChange, child: ...)`.
   - `DiscoverContentSelectorDialog`: 4 `radioWidget(...)` calls with `String` values inside a `Column > SingleChildScrollView > Column`. Wrap inner `Column` in `RadioGroup<String>(groupValue: controller.discoverContentType.value, onChanged: controller.onContentChange, child: ...)`.
   - Simplify `radioWidget()` to return `ListTile(leading: Radio(value: value), title: Text(label), onTap: ...)` — no `groupValue`/`onChanged` needed.

### R3 (onReorder → onReorderItem)

**`modification_list.dart`**: Rename `onReorder:` → `onReorderItem:`, remove the `if (old_ < new_) { new_--; }` block. The callback body becomes just the list reorder logic.

**`up_next_queue.dart`**: Rename `onReorder:` → `onReorderItem:`. No index compensation to remove — the old code passed indices directly to `playerController.onReorder()` without workaround.

### R6 (primaryColor → colorScheme.primary)

All 8 files use `Theme.of(context).primaryColor` as a surface/background color. Since the codebase uses `ColorScheme.fromSwatch()` with `primarySwatch`, `colorScheme.primary` returns the same value as the deprecated getter. Direct replacement — no context-appropriate `primaryContainer` needed.

**`cust_switch.dart`** note: Line 13 uses `themedata.value!.primaryColor` (not `Theme.of(context).primaryColor`). This access the same deprecated `ThemeData.primaryColor` getter and SHOULD be migrated to `themedata.value!.colorScheme.primary`.

## Interfaces / Contracts

No new interfaces. `RadioGroup<T>` is a Flutter SDK widget — no custom implementation needed.

```dart
// Before (add_to_playlist.dart)
Radio(value: "piped", groupValue: groupVal, onChanged: onChange)
Radio(value: "local", groupValue: groupVal, onChanged: onChange)

// After
RadioGroup<String>(
  groupValue: groupVal,
  onChanged: onChange,
  child: Row(children: [
    Radio(value: "piped"),
    SizedBox(width: 15),
    Radio(value: "local"),
  ]),
)
```

## Testing Strategy

| Layer | What | How |
|-------|------|-----|
| Static analysis | No deprecation infos | `flutter analyze` after each commit |
| Build | Debug APK builds | `flutter build apk --debug` after all commits |
| Verification | grep for remaining patterns | Search `.dart` for `\.red\b`, `onReorder:`, `activeColor:`, `indicatorColor:`, `primaryColor` |
| Manual | Radio widget trees | Visual smoke check on settings, add-to-playlist, create-playlist dialogs |
| Manual | Reorder behavior | Drag-reorder in modification list and up-next queue |

## Commit Strategy

1. `refactor: migrate color channel int accessors to channel* API` (R1)
2. `refactor: migrate Switch.activeColor to WidgetStateProperty` (R4)
3. `refactor: migrate ThemeData.indicatorColor to TabBarThemeData` (R5)
4. `refactor: migrate ReorderableListView onReorder to onReorderItem` (R3)
5. `refactor: migrate Radio groupValue/onChanged to RadioGroup<T>` (R2)
6. `refactor: replace Theme.of(context).primaryColor with colorScheme.primary` (R6)
7. `chore: verify flutter analyze baseline and build integrity` (R7+R8)

Each commit must leave the project buildable. Run `flutter analyze` after each commit.

## Migration / Rollback

No data migration. Each commit revertible independently. If R2 (Radio) causes visual issues, revert commit 5 only.

## Open Questions

- [ ] **cust_switch.dart**: `themedata.value!.primaryColor` accesses the same deprecated `ThemeData.primaryColor` getter as R6 but through a different path (GetX Rx<ThemeData>, not `Theme.of(context)`). Should this be included? Recommendation: yes — migrate to `themedata.value!.colorScheme.primary`.
- [ ] **ThemeData constructor `primaryColor:` params**: Lines 97, 167, 233 in `theme_controller.dart` use the deprecated `primaryColor:` constructor parameter. If `flutter analyze` flags these as info-level after R6, they need separate handling.
