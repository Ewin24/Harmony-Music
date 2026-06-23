# Tasks: Fix Home Content Vertical Gap

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~14 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single commit |
| Delivery strategy | ask-always |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | 3 edits in `quickpickswidget.dart` + verify | Single commit | All changes in one file, ~14 lines, no split needed |

## 1. Add empty-state guard at top of `build`
- [ ] Insert `if (content.songList.isEmpty) return const SizedBox.shrink();` at line 18 (before `PlayerController` lookup)
- **Done when**: empty `songList` renders zero-height widget
- **Files touched**: `lib/ui/widgets/quickpickswidget.dart`
- **Estimated lines**: ~2
- **Commit message**: part of combined commit below

## 2. Restructure outer container from `SizedBox(height: 340)` to `Column(mainAxisSize: min)`
- [ ] Replace `return SizedBox(height: 340, width: double.infinity, child: Column(mainAxisAlignment: MainAxisAlignment.start, ...)` with `return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, ...)`
- **Done when**: outer wrapper sizes to content, no fixed 340px minimum
- **Files touched**: `lib/ui/widgets/quickpickswidget.dart`
- **Estimated lines**: ~6
- **Depends on**: #1

## 3. Replace `Expanded` with `SizedBox(height: 280)` for the grid
- [ ] Replace `Expanded(child: Scrollbar(...GridView...))` with `SizedBox(height: 280, child: Scrollbar(...GridView...))`
- **Done when**: grid has fixed 280px height instead of stretching via Expanded
- **Files touched**: `lib/ui/widgets/quickpickswidget.dart`
- **Estimated lines**: ~4
- **Depends on**: #2

## 4. Final verification
- [ ] Run `flutter analyze` — expect "No issues found!"
- [ ] Run `flutter build apk --debug` — expect exit 0
- [ ] Hot reload on device — confirm empty state shows no gap
- [ ] Hot reload on device — confirm populated state gap ≤30px to next section
- [ ] Commit: `fix(home): collapse QuickPicksWidget when empty and reduce height`
- **Done when**: all checks pass, commit pushed
- **Files touched**: `lib/ui/widgets/quickpickswidget.dart`
- **Depends on**: #3
