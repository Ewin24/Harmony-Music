# Proposal: Fix home content vertical gap between QuickPicks and next section

## Intent

Users see the skeleton fill the screen well, but after loading, a ~30% vertical gap appears between the "Discover" header and the next section. The QuickPicksWidget has a fixed 340px height that doesn't adapt to actual content — when `songList` is empty or sparse, the grid area shows blank space, creating the visual gap.

## Scope

### In Scope
- Make QuickPicksWidget height adapt to its content (not fixed 340px)
- Hide QuickPicksWidget entirely when `songList` is empty
- Adjust grid layout when item count is below `crossAxisCount` (4 rows)
- Update `home-screen` spec with new adaptive-height requirement

### Out of Scope
- Other home screen widgets (ContentListWidget, shimmer)
- Scroll controller lifecycle changes
- API or data layer changes
- ContentListWidget height (separate concern, reported by one user)

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `home-screen`: Add requirement — QuickPicksWidget SHALL size to content so it never shows empty grid space. When `songList` is empty, the widget SHALL render zero-height (invisible).

## Approach

1. **Diagnose exact height**: Remove `SizedBox(height: 340)` and `Expanded`. Replace with a `SizedBox` whose height is computed from actual grid content (4 rows × item height + spacing) or 0 when empty.
2. **Empty-state guard**: `if (content.songList.isEmpty) return const SizedBox.shrink()` — eliminates 340px of blank space.
3. **Grid height fix**: Calculate grid height from `childAspectRatio` and `crossAxisCount` instead of letting `Expanded` stretch empty space. Dynamically reduce `crossAxisCount` when `songList.length < 4` and adjust `childAspectRatio` to maintain item proportions.
4. **Verify**: Run app, confirm gap is gone. Static review for `flutter analyze`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/ui/widgets/quickpickswidget.dart:19-36` | Modified | Replace fixed SizedBox + Expanded with content-adaptive sizing |
| `openspec/specs/home-screen/spec.md` | Modified | Add adaptive-height requirement |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Grid item height differs across screen densities | Low | Use `ListView` fallback for <4 items instead of grid |
| QuickPicks collapses when user expects empty space | Low | Empty = no data, collapse is correct — next section fills viewport |

## Rollback Plan

Revert `quickpickswidget.dart` to `SizedBox(height: 340)` and remove empty-state guard. One-file revert, no data migration.

## Dependencies

None.

## Success Criteria

- [ ] No gap visible between QuickPicks title and next section when QuickPicks has any items
- [ ] QuickPicks section disappears (zero height) when `songList` is empty
- [ ] `flutter analyze` passes with zero errors
- [ ] Visual: skeleton and loaded state have no vertical gap regressions
