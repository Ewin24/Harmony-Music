# Design: Enrich Home Content and Reduce Vertical Gap

## Technical Approach

Three minimal value-only changes across 3 files to increase home content density: bump default fetch limit from 3→9, expand user-selectable options, and tighten QuickPicks bottom padding from 20px→8px. No new logic, no new widgets, no controller refactoring. The spec's `Default Content Section Count` and `Reduced Vertical Gap` requirements drive every edit.

## Architecture Decisions

### Decision: Hive fallback alignment

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Change only field default (`= 3.obs` → `= 9.obs`) | Fresh installs would still get 3 because `_setInitValue` overwrites with `?? 3` | ❌ Rejected |
| Change BOTH field default AND `_setInitValue` fallback | Fresh installs init at 9; existing users keep their saved Hive value untouched | ✅ **Chosen** |

**Rationale**: The controller field declaration (`= 3.obs` on line 29) is immediately overwritten by `_setInitValue` (line 89: `setBox.get("noOfHomeScreenContent") ?? 3`) in `onInit()`. Changing only the field default produces zero behavioral change on fresh installs — the Hive fallback still emits 3. Both lines must change to 9 for the spec to be satisfied.

### Decision: Single commit over three

| Option | Tradeoff | Decision |
|--------|----------|----------|
| 3 separate commits | Cleaner diff per commit, but trivial changes (~6 lines) create noise | ❌ Rejected |
| 1 commit: `feat(home): enrich home with 9 default sections and reduce gap` | Reviewable in 30s, changes are independent and tested together | ✅ **Chosen** |

### Decision: Options exclude 3, add 15

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Keep 3 in options | Users who accidentally reset can still pick 3 (sparse layout) | ❌ Rejected |
| `[5, 7, 9, 11, 15]` | Removes the value that caused the sparse complaint; 15 available for power users | ✅ **Chosen** |

## Data Flow

```
SettingsScreen (dropdown)          SettingsScreenController          HomeScreenController
       │                                    │                              │
       │  setContentNumber(9)               │                              │
       ├───────────────────────────────────►│                              │
       │                                    │  setBox.put("noOfHomeScreenContent", 9)
       │                                    ├──────► Hive (AppPrefs)       │
       │                                    │                              │
       │    noOfHomeScreenContent (obs)     │                              │
       │◄───────────────────────────────────┤                              │
       │                                    │                              │
       │                                    │  loadContentFromNetwork()    │
       │                                    ├─────────────────────────────►│
       │                                    │        API: ?limit=9         │
       │                                    │        ◄─────── API ────────►│
```

On fresh install: `_setInitValue` reads Hive → key missing → fallback `9` (from the changed line 89) → `noOfHomeScreenContent.value = 9` → home fetches with limit=9.

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/ui/widgets/quickpickswidget.dart:134` | Modify | `SizedBox(height: 20)` → `SizedBox(height: 8)` — tighter bottom gap |
| `lib/ui/screens/Settings/settings_screen_controller.dart:29` | Modify | `= 3.obs` → `= 9.obs` — field default for new controller instances |
| `lib/ui/screens/Settings/settings_screen_controller.dart:89` | Modify | `?? 3` → `?? 9` — Hive fallback for fresh installs (**critical**, not in original proposal) |
| `lib/ui/screens/Settings/settings_screen.dart:242` | Modify | `[3, 5, 7, 9, 11]` → `[5, 7, 9, 11, 15]` — dropdown options |

## Interfaces / Contracts

No new interfaces. The `setContentNumber(int)` method on `SettingsScreenController` already accepts any `int` — 3 remains a valid runtime value even though it's no longer in the dropdown. No validation code needs updating.

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Static | Analyzer integrity | `flutter analyze` — must report zero issues |
| Build | Debug APK | `flutter build apk --debug` — must exit 0 |
| Manual | Visual on device | `flutter run` on Moto G60s: home shows ≥3 sections (up from 1-2), gap between QuickPicks and next section is 8px |

## Migration / Rollout

**Existing users**: Hive box retains their saved `noOfHomeScreenContent` value. If they had 3 saved, it stays 3 after upgrade. They see the new options `[5,7,9,11,15]` in the dropdown and can pick a higher value. No data migration needed.

**Fresh installs**: `_setInitValue` hits `?? 9` fallback on missing Hive key → home renders 9 sections.

**Edge case**: A user who had 3 saved and then resets to defaults via `resetAppSettingsToDefault()` will get 9 (the new field default) because `setBox.clear()` removes the key, and `_setInitValue` then hits `?? 9`.

## Open Questions

- [ ] Does the YouTube Music API reliably return 9+ sections with limit=9, or does it cap at fewer? (Spec assumes the API supports it — verify on device.)
- [ ] Will 15 as max selector cause performance issues for very slow networks? (Unlikely — sections are loaded lazily, but worth noting.)
