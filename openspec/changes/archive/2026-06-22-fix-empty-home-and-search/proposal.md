# Proposal: Fix empty home and empty search results

## Intent

Home screen shows skeleton loaders forever and search results display nothing in the initial "Results" tab — both are core user flows broken. Users cannot see content on app start nor find results after searching. These are production-blocking UX defects.

## Scope

### In Scope
- Fix `RangeError` crash in `HomeScreenController.loadContentFromNetwork()` that blocks content loading
- Fix `ResultWidget.generateWidgetList()` skipping playlist data so initial Results tab shows all categories
- Defensive guards for empty lists / missing keys in both controllers
- Restore commented-out playlist rendering and import in `search_related_widgets.dart`

### Out of Scope
- Refactoring `HomeScreenController.loadContentFromDb()` — works fine
- Refactoring `_setContentList()` null safety — low risk, scoped out
- The search endpoint, recommendation, or API layer — all work correctly
- UI redesign or skeleton state improvements

## Capabilities

### New Capabilities
- `home-screen`: Home screen content loading from network, caching, and rendering
- `search`: Search result display with tabbed categories (Songs, Albums, Playlists, etc.)

### Modified Capabilities
None — no existing specs to update. These are new capabilities for the SDD spec index.

## Approach

**Bug 1 — Home crash**: Add `if (index != -1)` guard before `homeContentListMap.removeAt(index)` at line 156. If "Quick picks" is missing, fall through gracefully — skip quick picks assignment and continue loading middle/fixed content. Same pattern already exists for "Trending" at line 99-101.

**Bug 2 — Search results display**: Uncomment the playlist rendering block (`ContentListWidget` with `PlaylistContent`) at lines 75-83 of `search_related_widgets.dart`. Uncomment the `Playlist` import at line 8 of the same file. Ensure the category check matches actual API response keys (e.g. "Community playlists", "Featured playlists").

Both fixes are minimal, isolated, and purely additive/defensive.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/ui/screens/Home/home_screen_controller.dart` | Modified | Lines 153-159: guard `removeAt` against -1 |
| `lib/ui/widgets/search_related_widgets.dart` | Modified | Lines 8, 75-83: uncomment playlist rendering |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Fallback quick picks still empty | Low | UI already handles empty quick picks gracefully |
| Playlist key mismatch in API response | Low | Keys checked: "Featured playlists" / "Community playlists" |

## Rollback Plan

Revert the two file changes. No schema changes, no DB migrations, no config changes.

## Dependencies

None.

## Success Criteria

- [ ] Home screen loads content (not skeletons) within 5s on cold start
- [ ] Search results show playlists in the initial Results tab (not just community playlists tab)
- [ ] No `RangeError` exceptions in logcat on app launch or search
