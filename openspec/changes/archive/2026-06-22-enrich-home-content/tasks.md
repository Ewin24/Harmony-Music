# Tasks: Enrich Home Content and Reduce Vertical Gap

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~6-7 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

## Phase 1: Core Edits

- [x] 1.1 **Reduce QuickPicks bottom padding** — `lib/ui/widgets/quickpickswidget.dart:134`: `SizedBox(height: 20)` → `SizedBox(height: 8)`
- [x] 1.2 **Bump field default** — `lib/ui/screens/Settings/settings_screen_controller.dart:29`: `= 3.obs` → `= 9.obs`
- [x] 1.3 **Bump Hive fallback** — `lib/ui/screens/Settings/settings_screen_controller.dart:89`: `?? 3` → `?? 9`
- [x] 1.4 **Update settings options** — `lib/ui/screens/Settings/settings_screen.dart:242`: `[3, 5, 7, 9, 11]` → `[5, 7, 9, 11, 15]`
- **Done when**: all 4 edits applied; gap should be 8px, default content count 9, dropdown excludes 3
- **Files touched**: 3 files (4 edits)
- **Estimated lines**: ~6-7
- **Commit message**: `feat(home): enrich home with 9 default sections and reduce gap`
- **Depends on**: none

## Phase 2: Verification

- [x] 2.1 **Static analyze** — `flutter analyze` must report 0 errors, 0 warnings
- [x] 2.2 **Build check** — `flutter build apk --debug` must exit 0
- [x] 2.3 **Manual verify** — hot reload on device: home shows ≥3 sections; gap between QuickPicks and next section is visibly smaller
- [x] 2.4 **Commit** — `git add -A && git commit -m "feat(home): enrich home with 9 default sections and reduce gap"`
- **Done when**: all checks pass and commit is made
- **Files touched**: same 3 files
- **Estimated lines**: 0 new
- **Depends on**: 1.1, 1.2, 1.3, 1.4
