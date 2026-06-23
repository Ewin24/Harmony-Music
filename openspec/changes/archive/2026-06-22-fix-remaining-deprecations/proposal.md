# Proposal: Fix Remaining Flutter Deprecation Infos

## Intent

Clean the last 29 info-level deprecation notices from `flutter analyze`. The previous change (`fix-flutter-deprecation-warnings`) resolved 0 errors + 0 warnings, leaving these explicitly as follow-up. Future Flutter releases turn these into errors, so addressing them now keeps the project modern and SDK-upgrade-safe.

## Scope

### In Scope
- Source `.dart` files under `lib/`
- Mechanical API replacements per category
- `ThemeData.primaryColor` and `primaryColor` getter cleanup (info-level deprecations)

### Out of Scope
- Third-party packages' own deprecation warnings
- Generated/build artifacts
- MD2→MD3 theme architecture migration
- Any semantic or visual changes beyond the API rename

## Capabilities

### New Capabilities
None — refactor only, no new feature.

### Modified Capabilities
- `deprecation-cleanup` — extend Zero-Analyze Baseline requirement to cover info-level deprecations

## Approach

Per-category hand-edit, one commit per category for independent revert. Categories ordered by risk (low→medium):

| # | Category | Migration | Risk |
|---|----------|-----------|------|
| 1 | `ReorderableListView.onReorder` → `onReorderItem` | Rename + remove manual newIndex compensation | Low |
| 2 | `Switch.activeColor` → `fillColor` via `WidgetStateProperty` | 1 property rename | Low |
| 3 | `ThemeData.indicatorColor` → `TabBarTheme.indicatorColor` | Move property to TabBarThemeData | Low |
| 4 | `Color.red/green/blue/alpha` → `channelRed/Green/Blue/Alpha` | Rename 4 getters (int→int, same semantics) | Low |
| 5 | `Radio.groupValue` + `Radio.onChanged` → `RadioGroup` wrapper | Wrap siblings in `RadioGroup<T>(...)` | Medium |
| 6 | `Theme.of(context).primaryColor` → `colorScheme.*` equivalent | Replace getter read per context (~12×) | Medium |

## Categorized Deprecations

### 1. Color channel accessors (`.red`/`.green`/`.blue`/`.alpha`)
- **Count**: 10 occurrences
- **File**: `lib/ui/utils/theme_controller.dart` (lines 298, 321-323, 334-337)
- **Replacement**: `color.red` → `color.channelRed` (int→int, no arithmetic change)
- **Risk**: Low

### 2. Radio API redesign (`groupValue` + `onChanged`)
- **Count**: 5 Radio instances × 2 deprecated params = 10 deprecations
- **Files**: `add_to_playlist.dart` (2×), `settings_screen.dart` (1×), `create_playlist_dialog.dart` (2×)
- **Replacement**: Wrap each group in `RadioGroup<T>(groupValue: ..., onChanged: ..., child: Row(...))`
- **Risk**: Medium — widget tree restructuring with GetX reactive patterns in scope

### 3. ReorderableListView `onReorder` → `onReorderItem`
- **Count**: 2 occurrences
- **Files**: `modification_list.dart`, `up_next_queue.dart`
- **Replacement**: `onReorder:` → `onReorderItem:`, remove `if (old < new) new--` workaround
- **Risk**: Low — both handlers already have simple reorder logic

### 4. `Switch.activeColor` → `fillColor`
- **Count**: 1 occurrence
- **File**: `lib/ui/widgets/cust_switch.dart` (line 16)
- **Replacement**: `activeColor: Colors.white` → `fillColor: WidgetStateProperty.resolveWith(...)`
- **Risk**: Low

### 5. `ThemeData.indicatorColor` → `TabBarTheme.indicatorColor`
- **Count**: 1 occurrence
- **File**: `lib/ui/utils/theme_controller.dart` (line 130)
- **Replacement**: Move `indicatorColor` from `ThemeData()` into a `TabBarThemeData()` sub-theme
- **Risk**: Low

### 6. `Theme.of(context).primaryColor` getter reads
- **Count**: 12 occurrences (potential additional infos)
- **Files**: `player.dart`, `bottom_nav_bar.dart`, `lyrics_switch.dart`, `standard_player.dart`, `gesture_player.dart`, `search_result_screen_v2.dart`, `side_nav_bar.dart`
- **Replacement**: Per-context — `colorScheme.primary` or `colorScheme.primaryContainer` as appropriate
- **Risk**: Medium — requires context-aware color mapping, possible visual difference

## Estimated Changed Lines

| Category | Files | Lines |
|----------|-------|-------|
| Color channel accessors | 1 | 10 |
| Radio → RadioGroup | 3 | ~25 |
| ReorderableListView | 2 | 4 |
| Switch.activeColor | 1 | 2 |
| ThemeData.indicatorColor | 1 | 3 |
| Theme.of(context).primaryColor | 7 | 12 |
| **Total** | **~9 files** | **~56 lines** |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| RadioGroup wrap changes widget tree layout | Low | Verify each screen visually |
| `primaryColor` → `colorScheme.primary` changes color | Medium | Test on light + dark themes |
| Manual newIndex removal in `onReorderItem` breaks reorder logic | Low | Verify reorder works on both list screens |

## Rollback Plan

Each category is a separate commit → revert individual commits. Test with `flutter analyze` after each commit.

## Dependencies

- Flutter SDK (for `flutter analyze` verification)

## Success Criteria

- [ ] `flutter analyze` returns "No issues found!" (exit 0)
- [ ] App builds for target platform
- [ ] No visual regression on light & dark theme screens
- [ ] Reorder works correctly in both `modification_list` and `up_next_queue`

## Open Questions

1. **primaryColor bucket**: Are `ThemeData.primaryColor` (constructor) and `Theme.of(context).primaryColor` (getter) info-level or warning-level? If already warnings, they may have been included in the first fix scope but deferred. Needs `flutter analyze` to confirm.
2. **Radio migration strategy**: `RadioGroup` wrapper works for simple groups. The settings_screen.dart Radio uses type-inferred groupValue correctly — confirm no type issues.
3. **Color channel migration**: Use `channelRed/Green/Blue/Alpha` (int→int, same 0-255 range) for existing int arithmetic, or switch to `r/g/b/a` (double 0-1) for modern approach? Proposal recommends `channel*` to keep math unchanged.
