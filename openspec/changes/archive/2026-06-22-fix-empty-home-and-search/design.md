# Design: Fix empty home screen and empty search results

## Technical Approach

Two independent defensive fixes — no architectural changes, no new files, no refactoring.

- **Fix 1 (home)**: Guard `removeAt(index)` against `index == -1` when "Quick picks" is missing from the API response. Also guard `rel.removeAt(0)` against empty list for BOLI content type.
- **Fix 2 (search)**: Restore commented-out playlist import and rendering block so playlists appear in search Results tab.

Both mirror existing patterns in the codebase (the Trending guard at lines 99-101 and the Artist rendering at lines 84-89).

## Architecture Decisions

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Guard `index != -1` vs. try/catch round the block | try/catch masks all errors including legit ones; specific guard is self-documenting | **Guard with `if (index != -1)`** — follows the exact Trending pattern at lines 99-101 |
| Guard `rel.isNotEmpty` vs. rely on existing try/catch (line 137) | Existing catch IS active but `rel.isNotEmpty` makes intent explicit | **Add `rel.isNotEmpty` guard** — defensive coding; the try/catch is a safety net, not the first line of defense |
| Extract playlist into shared category helper vs. restore inlined | Extraction would touch 3+ files for no gain | **Restore inlined** — reverts to original working state, minimal diff |

## Data Flow

```
Fix 1 flow (home_screen_controller.dart:153-159):

  loadContentFromNetwork()
    → contentType != "TR"/"TMV"/"BOLI" (falls to QP path)
    → homeContentListMap.indexWhere(title == "Quick picks")
    → if (index != -1) → removeAt(index) → assign quickPicks  ✓
    → if (index == -1) → skip block → continue to middle/fixed  ✓


Fix 2 flow (search_related_widgets.dart:58-93):

  generateWidgetList(resultContent.entries)
    → for each entry:
      "Songs"/"Videos"       → SeparateTabItemWidget  ✓
      "Albums"               → ContentListWidget      ✓
      contains("playlist")   → UNCOMMENTED → renders  ✓  (was broken)
      contains("Artist")     → SeparateTabItemWidget  ✓
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/ui/screens/Home/home_screen_controller.dart` | Modify | Lines 153-159: guard `removeAt` with `index != -1`. Line 142: add `rel.isNotEmpty` guard. |
| `lib/ui/widgets/search_related_widgets.dart` | Modify | Line 8: uncomment `import ...playlist.dart`. Lines 75-83: uncomment playlist rendering block. |

## Interfaces / Contracts

No new interfaces. Both fixes restore existing contracts:
- `QuickPicks(List<MediaItem>, {String? title})` — already handles empty list
- `PlaylistContent({List<Playlist>? playlistList, String? title})` — already handles empty list
- `ContentListWidget({ContentListInterface? content, bool isHomeContent})` — already handles null/empty

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Static | `flutter analyze` | Zero errors, zero warnings |
| Build | `flutter build apk --debug` | Exit code 0, APK produced |
| Integration | Home screen loads content | No RangeError in logcat, skeletons resolve within 5s |
| Integration | Search shows playlists | "Featured playlists" / "Community playlists" visible in Results tab |

## Migration / Rollout

No migration required. Both fixes are source-only changes with zero data impact. Revert by reverting the two file modifications.

## Open Questions

- [ ] The search file path in the initial task description (`lib/ui/screens/Search/search_related_widgets.dart`) does not match the actual file (`lib/ui/widgets/search_related_widgets.dart`). Confirmed against codebase — design uses the real path.
- [ ] Does the BOLI `rel.isNotEmpty` guard need to also check `rel[0]["contents"]` is non-empty? The try/catch at line 147 would catch `removeAt(0)` on empty list, but `rel[0]` access would not throw on a non-empty list. Low risk — the song API for BOLI always returns list entries with "contents" when non-empty.
