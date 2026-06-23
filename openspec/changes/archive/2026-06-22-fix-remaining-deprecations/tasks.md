# Tasks: Fix Remaining Flutter Deprecation Infos

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~60-70 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR with 6 migration commits + 1 verification pass |
| Delivery strategy | ask-always |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | All 6 migration categories + verification | Single PR (7 commits) | Independent revert per commit; `flutter analyze` after each commit |

## Phase 1: Color Channel Accessors (R1)

- [x] 1.1 In `lib/ui/utils/theme_controller.dart`, replace `color.red`/`color.green`/`color.blue`/`color.alpha` int getters with `(color.r*255.0).round().clamp(0,255)` formula (12 lines)
- **Done when**: grep for `\.red\b|\.green\b|\.blue\b|\.alpha\b` in theme_controller.dart returns 0 matches on Color expressions
- **Files touched**: `lib/ui/utils/theme_controller.dart`
- **Estimated lines**: ~10
- **Commit message**: `refactor: migrate color channel int accessors to channel* API`
- **Depends on**: nothing

## Phase 2: Switch.activeColor → thumbColor (R4)

- [x] 2.1 In `lib/ui/widgets/cust_switch.dart`, replace `activeColor: Colors.white` with `thumbColor: WidgetStateProperty.all(Colors.white)`
- **Done when**: grep for `activeColor:` returns 0 matches in `cust_switch.dart`
- **Files touched**: `lib/ui/widgets/cust_switch.dart`
- **Estimated lines**: ~2
- **Commit message**: `refactor: migrate Switch.activeColor to thumbColor WidgetStateProperty`
- **Depends on**: 1

## Phase 3: ThemeData.indicatorColor → TabBarThemeData (R5)

- [x] 3.1 In `lib/ui/utils/theme_controller.dart`, move `indicatorColor` from `ThemeData()` constructor into a nested `tabBarTheme: TabBarThemeData(indicatorColor: ...)` (3 lines)
- **Done when**: grep for `indicatorColor:` inside `ThemeData(` returns 0 matches
- **Files touched**: `lib/ui/utils/theme_controller.dart`
- **Estimated lines**: ~3
- **Commit message**: `refactor: migrate ThemeData.indicatorColor to tabBarTheme`
- **Depends on**: 2

## Phase 4: ReorderableListView onReorder → onReorderItem (R3)

- [x] 4.1 In `lib/ui/widgets/modification_list.dart`, rename `onReorder:` → `onReorderItem:`, remove the `if (old_ < new_) { new_--; }` workaround
- [x] 4.2 In `lib/ui/widgets/up_next_queue.dart`, rename `onReorder:` → `onReorderItem:` (no workaround to remove)
- **Done when**: grep for `onReorder:` on ReorderableListView instances returns 0 matches
- **Files touched**: `lib/ui/widgets/modification_list.dart`, `lib/ui/widgets/up_next_queue.dart`
- **Estimated lines**: ~4
- **Commit message**: `refactor: migrate ReorderableListView onReorder to onReorderItem`
- **Depends on**: 3

## Phase 5: Radio → RadioGroup<T> (R2)

- [x] 5.1 In `lib/ui/widgets/add_to_playlist.dart`, wrap 2 Radio siblings in `RadioGroup<String>(groupValue:, onChanged:, child: Row(...))`, remove `groupValue`/`onChanged` from each Radio
- [x] 5.2 In `lib/ui/widgets/create_playlist_dialog.dart`, same pattern — wrap 2 Radios in `RadioGroup<String>(...)`
- [x] 5.3 In `lib/ui/screens/Settings/settings_screen.dart`, wrap 4 `radioWidget` ThemeType calls in `RadioGroup<ThemeType>(...)` and 4 String calls in `RadioGroup<String>(...)`, simplify `radioWidget()` to omit groupValue/onChanged
- **Done when**: grep for `groupValue:` or `onChanged:` on `Radio(` widget instances (outside RadioGroup) returns 0 matches; project compiles
- **Files touched**: `lib/ui/widgets/add_to_playlist.dart`, `lib/ui/widgets/create_playlist_dialog.dart`, `lib/ui/screens/Settings/settings_screen.dart`
- **Estimated lines**: ~30-40
- **Commit message**: `refactor: migrate Radio groupValue/onChanged to RadioGroup<T> wrapper`
- **Depends on**: 4

## Phase 6: Theme.of(context).primaryColor → colorScheme.primary (R6)

- [x] 6.1 Replace `Theme.of(context).primaryColor` with `colorScheme.primary` in 8 files: `player.dart`, `bottom_nav_bar.dart`, `lyrics_switch.dart`, `standard_player.dart`, `gesture_player.dart`, `albumart_lyrics.dart`, `search_result_screen_v2.dart`, `side_nav_bar.dart`
- [x] 6.2 In `lib/ui/widgets/cust_switch.dart`, migrate `themedata.value!.primaryColor` → `themedata.value!.colorScheme.primary`
- **Done when**: grep for `\.primaryColor` in `lib/` returns 0 matches (excluding non-Dart refs)
- **Files touched**: `lib/ui/player/player.dart`, `lib/ui/widgets/bottom_nav_bar.dart`, `lib/ui/player/components/lyrics_switch.dart`, `lib/ui/player/components/standard_player.dart`, `lib/ui/player/components/gesture_player.dart`, `lib/ui/player/components/albumart_lyrics.dart`, `lib/ui/screens/Search/search_result_screen_v2.dart`, `lib/ui/widgets/side_nav_bar.dart`, `lib/ui/widgets/cust_switch.dart`
- **Estimated lines**: ~20
- **Commit message**: `refactor: replace Theme.of(context).primaryColor with colorScheme.primary`
- **Depends on**: 5

## Phase 7: Final Verification

- [x] 7.1 Run `flutter analyze` — 0 errors, 0 warnings (1 pre-existing experimental warning), 0 deprecation infos
- [x] 7.2 Run `flutter build apk --debug` — exit 0, APK produced (189MB debug)
- [x] 7.3 Run final grep sweeps: all 0 matches
- **Done when**: analyze clean, build green, all greps 0
- **Files touched**: none (verification only)
- **Estimated lines**: 0
- **Commit message**: (no commit — verification pass)
- **Depends on**: 6
