# Delta for deprecation-cleanup

## ADDED Requirements

### Requirement: Color Channel Accessor Migration (red/green/blue/alpha → channelRed/Green/Blue/Alpha)

The system MUST replace deprecated `Color.red`, `Color.green`, `Color.blue`, and `Color.alpha` int getter reads with `channelRed`, `channelGreen`, `channelBlue`, and `channelAlpha` respectively.

#### Scenario: No deprecated channel accessors remain

- GIVEN `lib/ui/utils/theme_controller.dart`
- WHEN grepping for `\.red\b`, `\.green\b`, `\.blue\b`, `\.alpha\b` on Color expressions
- THEN zero matches SHALL exist; all SHALL use `channelRed`, `channelGreen`, `channelBlue`, `channelAlpha`

#### Scenario: Channel math equivalence is preserved

- GIVEN `channelRed`/`channelGreen`/`channelBlue`/`channelAlpha` return identical int values (0–255) as the deprecated int getters
- WHEN the migration is applied
- THEN no arithmetic logic SHALL change; only the accessor name differs

### Requirement: Radio → RadioGroup<T> Migration

The system MUST replace deprecated `Radio.groupValue` + `Radio.onChanged` patterns with `RadioGroup<T>(groupValue:, onChanged:, child: Row(...))` wrappers.

#### Scenario: No deprecated Radio parameters remain

- GIVEN `lib/` directory
- WHEN searching `.dart` files for `groupValue:` or `onChanged:` on `Radio(` widget instances
- THEN zero detections SHALL remain outside the `RadioGroup` wrapper

#### Scenario: RadioGroup wraps sibling Radios correctly

- GIVEN each existing `Radio` group in `add_to_playlist.dart`, `settings_screen.dart`, and `create_playlist_dialog.dart`
- WHEN the migration is applied
- THEN all sibling `Radio` widgets within one group SHALL be children inside a single `RadioGroup<T>` with `groupValue` and `onChanged` hoisted to the wrapper

#### Scenario: Type inference for GroupValue<T> holds

- GIVEN the `RadioGroup<T>` wrapper infers `T` from the `groupValue` parameter
- WHEN `settings_screen.dart`'s type-inferred groupValue is migrated
- THEN the code SHALL compile without type errors

### Requirement: ReorderableListView onReorder → onReorderItem

The system MUST replace deprecated `ReorderableListView.onReorder` with `onReorderItem` and remove the manual `if (oldIndex < newIndex) newIndex--` index compensation.

#### Scenario: No onReorder calls remain

- GIVEN `lib/` directory
- WHEN grepping for `onReorder:` on `ReorderableListView` instances
- THEN zero matches SHALL exist; all SHALL use `onReorderItem:`

#### Scenario: Old/new index handling is correct

- GIVEN the `onReorderItem` callback receives `(oldIndex, newIndex)` directly from Flutter
- WHEN `modification_list.dart` and `up_next_queue.dart` handlers are migrated
- THEN the manual `if (oldIndex < newIndex) newIndex--` block SHALL be removed and reorder behavior SHALL remain correct

### Requirement: Switch.activeColor → WidgetStateProperty fillColor

The system MUST replace deprecated `Switch.activeColor` with `fillColor: WidgetStateProperty.resolveWith(...)`.

#### Scenario: activeColor is removed

- GIVEN `lib/ui/widgets/cust_switch.dart`
- WHEN checking the `Switch(` constructor call
- THEN `activeColor:` SHALL NOT be present; `fillColor:` SHALL use `WidgetStateProperty.resolveWith` instead

#### Scenario: Active-state color is preserved

- GIVEN the replacement maps `WidgetState.selected` states to `Colors.white`
- WHEN the Switch is toggled ON
- THEN the active thumb color SHALL remain visually identical to pre-migration

### Requirement: ThemeData.indicatorColor → TabBarThemeData.indicatorColor

The system MUST migrate `indicatorColor` from the `ThemeData()` constructor into a `TabBarThemeData` sub-theme within the same `ThemeData` call.

#### Scenario: indicatorColor is removed from ThemeData

- GIVEN `lib/ui/utils/theme_controller.dart`
- WHEN checking each `ThemeData(` constructor call
- THEN `indicatorColor:` SHALL NOT be a direct parameter; it SHALL exist inside a `tabBarTheme: TabBarThemeData(indicatorColor: ...)` parameter

#### Scenario: Tab indicator rendering is unchanged

- GIVEN the `TabBar` widget reads `indicatorColor` from the resolved `TabBarTheme`
- WHEN the migrated `TabBarThemeData.indicatorColor` value matches the previous `ThemeData.indicatorColor` value
- THEN the tab bar indicator SHALL render identically

### Requirement: Theme.of(context).primaryColor → colorScheme.primary

The system MUST replace all `Theme.of(context).primaryColor` getter reads with the equivalent `Theme.of(context).colorScheme.primary` (or `colorScheme.primaryContainer` where context-appropriate).

#### Scenario: No primaryColor getter reads remain

- GIVEN the project's `lib/` directory
- WHEN grepping `.dart` files for `Theme.of(context).primaryColor`
- THEN zero matches SHALL exist in live code

#### Scenario: Replacement uses context-appropriate colorScheme property

- GIVEN each `primaryColor` getter read across 7 files (`player.dart`, `bottom_nav_bar.dart`, `lyrics_switch.dart`, `standard_player.dart`, `gesture_player.dart`, `search_result_screen_v2.dart`, `side_nav_bar.dart`)
- WHEN the migration is applied
- THEN each replacement SHALL use `colorScheme.primary` (or `primaryContainer` where the visual context demands a container variant)

#### Scenario: Light and dark theme rendering is preserved

- GIVEN the app is built with the migration applied
- WHEN viewing affected screens under default light and dark themes
- THEN colors derived from the replacement SHALL appear visually consistent with pre-migration builds

### Requirement: Extended Zero-Analyze Baseline

`flutter analyze` executed from the project root MUST report zero errors, zero warnings, and zero info-level deprecation notices. No deprecation of any severity level SHALL remain after this change.

#### Scenario: Analyze reports no issues

- GIVEN all deprecation fixes from both changes are applied and Flutter SDK is on PATH
- WHEN running `flutter analyze`
- THEN output SHALL end with "No issues found!" and exit code SHALL be 0

### Requirement: Build Integrity Preservation

`flutter build apk --debug` MUST still succeed after all deprecation replacements from this change.

#### Scenario: Debug APK builds cleanly

- GIVEN Flutter SDK is on PATH and dependencies are resolved
- WHEN running `flutter build apk --debug`
- THEN command SHALL exit with code 0 and produce an APK at `build/app/outputs/flutter-apk/app-debug.apk`

## Non-Functional

| Concern | Requirement |
|---------|------------|
| **Mechanicity** | Replacements SHALL be mechanical: no semantic change to color values, layout, or rendering |
| **Commit granularity** | Each deprecation category (6 total) SHALL be a separate commit to enable independent revert |
| **Scope boundary** | Only `lib/` source files; no third-party packages, generated code, or build artifacts |
