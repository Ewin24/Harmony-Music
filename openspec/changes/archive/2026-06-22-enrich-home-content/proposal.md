# Proposal: Enrich home content and reduce vertical gap

## Intent

Users report the home screen feels sparse — only 1–2 content sections visible, with an awkward gap between the "Discover" header and the first content section below it. Root cause: the default content fetch limit is 3 (too low), and QuickPicksWidget has 20px of bottom padding (too much).

## Scope

### In Scope
- Reduce QuickPicksWidget bottom padding from 20px to 8px
- Increase default `noOfHomeScreenContent` from 3 to 9
- Change `noOfHomeScreenContent` options from `[3,5,7,9,11]` to `[5,7,9,11,15]`
- Verify API returns richer content with higher limit

### Out of Scope
- New API endpoints or data sources (home API already supports all categories)
- Refactoring `_setContentList` filtering logic
- Redesign of skeletons, shimmer, or error states
- Changing the discover content type settings (QP/TR/TMV/BOLI)

## Capabilities

### New Capabilities
None — no new spec-level capability introduced.

### Modified Capabilities
None — existing `home-screen` spec covers content loading behavior; this change only adjusts defaults and visual spacing, which don't alter loading requirements.

## Approach

1. **Gap fix**: Change `const SizedBox(height: 20)` → `const SizedBox(height: 8)` in `quickpickswidget.dart` line 134.
2. **Content default**: Change `final noOfHomeScreenContent = 3.obs` → `= 9.obs` in `settings_screen_controller.dart` line 29.
3. **Options update**: Change dropdown items from `[3,5,7,9,11]` to `[5,7,9,11,15]` in `settings_screen.dart` line 242.
4. **Verify**: Static review only (no Flutter SDK in env) — confirm padding renders tighter and home API returns ≥5 sections with limit=9.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/ui/widgets/quickpickswidget.dart:134` | Modified | Bottom padding 20 → 8px |
| `lib/ui/screens/Settings/settings_screen_controller.dart:29` | Modified | Default content limit 3 → 9 |
| `lib/ui/screens/Settings/settings_screen.dart:242` | Modified | Options `[3,5,7,9,11]` → `[5,7,9,11,15]` |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| API returns fewer sections than limit (no-op) | High | No crash — home already handles fewer items gracefully |
| Padding change breaks other layout | Low | Bottom margin only affects gap to next list item; content list has no top padding dependency |
| Users on 3-setting lose their saved value | Med | Hive read fallback defaults to 9 on missing key; migration is automatic |

## Rollback Plan

Revert the 3 changed values in order: default (back to 3), options (back to `[3,5,7,9,11]`), padding (back to 20px). No data migration needed.

## Dependencies

None — all changes are self-contained within 3 files.

## Success Criteria

- [ ] QuickPicksWidget bottom margin is visually tighter (20px → 8px)
- [ ] New installs default to fetching 9 home content sections instead of 3
- [ ] Settings dropdown offers `[5,7,9,11,15]` without 3
- [ ] No analyzer errors or warnings (`flutter analyze`)
