# Proposal: Fix Flutter 3.44+ Deprecation Warnings

## Intent

The codebase accumulated deprecation warnings across three Flutter releases (3.27→3.35→3.44). These become errors in future Flutter versions. Cleaning them now keeps the project on a modern foundation and makes SDK upgrades cheaper. This was a known follow-up from the `flutter-dev-environment-setup` change.

`flutter analyze` is not available in this environment (Flutter SDK not on PATH), so cataloging was done via codebase search for known deprecated APIs.

## Scope

### In Scope
- Source files under `lib/` (all `.dart` files)
- `test/` — only if tests use deprecated APIs (1 file: `test/widget_test.dart`)
- Mechanical API replacements where no semantic change
- `SystemUiOverlayStyle` deprecated property removal

### Out of Scope
- Third-party packages' own deprecation warnings
- Generated files, build artifacts
- Theme architecture redesign (MD2→MD3 migration) — only minimal fixes
- Any change that alters visual output or behavior

## Capabilities

### New Capabilities
None — refactor only, no new feature.

### Modified Capabilities
None — no spec-level behavior changes.

## Approach

One category at a time, from safest to riskiest:

| Step | Category | Migration | Risk |
|------|----------|-----------|------|
| 1 | `withOpacity(x)` → `withValues(alpha: x)` | Mechanical find-replace per file | Low |
| 2 | `Color.value` → `.toARGB32()` | 1 instance in theme_controller.dart | Low |
| 3 | `SystemUiOverlayStyle.*ContrastEnforced` | Remove deprecated properties | Low |
| 4 | ThemeData constructor legacy props → colorScheme equivalents | theme_controller.dart bulk rewrite | Medium |
| 5 | ThemeData getter reads → colorScheme.* | `Theme.of(context).canvasColor` → `colorScheme.surface`, etc. | Medium |

**Execution**: Apply per-file with human review of each hunk. Avoid bulk `dart fix --apply` unless the user approves after reviewing the diff.

## Categorized Deprecations

### 1. `Color.withOpacity` → `withValues(alpha:)`
- **Count**: 29 occurrences
- **Files**: 15 files (player.dart, albumart_lyrics.dart, gesture_player.dart, mini_player.dart, standard_player.dart, player_control.dart, home.dart, theme_controller.dart, playlist_export_dialog.dart, cust_switch.dart, sliding_up_panel.dart, up_next_queue.dart)
- **Example**: `Colors.white.withOpacity(0.5)` → `Colors.white.withValues(alpha: 0.5)`

### 2. `Color.value` getter → `toARGB32()`
- **Count**: 1 occurrence
- **File**: `lib/ui/utils/theme_controller.dart:85`

### 3. `SystemUiOverlayStyle` deprecated booleans
- **Count**: 6 occurrences (3 files × 2 properties)
- **File**: `lib/ui/utils/theme_controller.dart` (lines 99-100, 179-180, 250-251)

### 4. ThemeData constructor deprecated properties
- **Count**: ~18 occurrences
- **File**: `lib/ui/utils/theme_controller.dart` — `accentColor` (3×), `canvasColor` (3×), `cardColor` (2×), `dialogBackgroundColor` (1×), `primaryColorLight` (3×), `primaryColorDark` (2×), `backgroundColor` (3×)
- **Replacement**: Use `colorScheme.secondary`, `colorScheme.surface`, etc.

### 5. ThemeData getter reads (deprecated read paths)
- **Count**: ~30 occurrences
- **Files**: ~15 files across the codebase
  - `canvasColor` reads: 15 occurrences in 10 files
  - `cardColor` reads: 10 occurrences in 5 files
  - `primaryColorLight` reads: 2 occurrences in 2 files
  - `scaffoldBackgroundColor` reads: 2 occurrences in 1 file
  - `dividerColor` reads: 3 occurrences in 1 file
- **Replacement**: `Theme.of(context).colorScheme.surface` (or `surfaceContainerLow` / `outlineVariant` as appropriate)

## Estimated Changed Lines

| Category | Files | Lines Changed |
|----------|-------|--------------|
| `withOpacity` replacements | 15 | 29 |
| `Color.value` → `toARGB32()` | 1 | 1 |
| `SystemUiOverlayStyle` cleanup | 1 | 6 |
| ThemeData constructor (theme_controller) | 1 | ~18 |
| ThemeData getter reads | ~15 | ~30 |
| **Total** | **~20 files** | **~84 lines** |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| ThemeData getter replacement changes visual output (e.g. `canvasColor` vs `colorScheme.surface` may differ) | Medium | Review each replacement against the UI context; test on both dark/light themes |
| Missed deprecation without analyzer | Low | Run `flutter analyze` when SDK is available and cross-check |
| `dart fix --apply` over-applies | Low | Hand-edit with per-hunk review; no bulk tool without approval |

## Rollback Plan

1. Each category is a separate commit → revert individual commits
2. Keep the full `git diff` before applying any colorScheme replacements that have visual ambiguity
3. After all changes, `flutter analyze` should show 0 issues

## Dependencies

- Flutter SDK (for final `flutter analyze` verification)
- Existing CI workflow `.github/workflows/code_quality.yml` runs `flutter analyze`

## Success Criteria

- [ ] `flutter analyze` returns 0 issues
- [ ] App builds successfully (`flutter build apk` or `flutter build windows`)
- [ ] No visual regression in light & dark themes

## Open Questions

1. **Auto vs manual**: Use `dart fix --dry-run` to preview, then `--apply` selectively, or hand-edit everything? Proposal recommends hand-editing for ThemeData properties and mechanical find-replace for `withOpacity`.
2. **colorScheme mapping**: For `canvasColor` → `colorScheme.surface` vs `colorScheme.surfaceContainerLow` — verify visually on each screen.
3. **ThemeData constructor MD2→MD3**: `useMaterial3: false` is set everywhere. Should we switch to MD3 as part of this change? (Deferred — out of scope.)
