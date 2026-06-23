# Design: Migrate Plugins to Built-in Kotlin

## Technical Approach

Flutter 3.24+ warns when the Kotlin Gradle Plugin (KGP) is applied manually. In Flutter 3.5+, this becomes a hard error. The migration has **two separable concerns**: (1) app-level KGP removal (critical), and (2) plugin KGP resolution (blocked upstream).

The app-side migration is straightforward: remove `id "kotlin-android"` from `app/build.gradle`, migrate `kotlinOptions` to the `kotlin { compilerOptions { ... } }` DSL, and remove the `android.builtInKotlin=false` flag from `gradle.properties`.

**Critical discovery**: None of the 5 target plugins (audiotags 1.4.5, package_info_plus 10.1.0, share_plus 13.1.0, wakelock_plus 1.6.1, terminate_restart 1.1.0) support built-in Kotlin — they all still `apply plugin: 'kotlin-android'` in their build.gradle. Plugin upgrades alone do NOT eliminate plugin-level KGP warnings. This is an upstream limitation.

## Architecture Decisions

### Decision: Plugin KGP — defer to upstream

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Fork & patch each plugin | High maintenance burden, forks drift from upstream | ❌ |
| Accept warnings until upstream fixes land | Low risk in 3.24 (warning, not error); follow-up when 3.5+ nears | ✅ |
| Gradle substitution/override | Fragile, per-plugin build logic | ❌ |

**Rationale**: Flutter 3.24 treats plugin KGP as a warning, not a blocking error. The app-level KGP is the hard blocker. We proceed with app migration + plugin upgrades for general compatibility, and flag plugin KGP for upstream tracking.

### Decision: terminate_restart source

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Keep git fork (eb505e07) | Custom features; fork has KGP | ❌ |
| Switch to pub ^1.1.0 | Official releases; also has KGP; loses custom fork features | ✅ |

**Rationale**: Neither fork nor pub removes KGP. Pub version 1.1.0 has more features, fixes, and is maintainable. The fork's custom features are unknown/unverified — pub is safer.

### Decision: Commit strategy

**Recommendation**: 2 commits — (1) app-side cleanup, (2) all plugin upgrades in one commit.

**Rationale**: Plugin upgrades are tested together as a unit. Separate commits for each plugin adds review overhead with no isolation benefit — if a plugin breaks, pin that one.

## Data Flow

```
Before:
  app/build.gradle ──→ applies KGP manually (hard error in 3.5+)
  gradle.properties ──→ android.builtInKotlin=false (disables FGP built-in)
  plugins/*/build.gradle ──→ apply kotlin-android (warning in 3.24)

After:
  app/build.gradle ──→ no KGP (FGP applies it automatically)
  gradle.properties ──→ no builtInKotlin flag (defaults to true)
  plugins/*/build.gradle ──→ still apply kotlin-android (KNOWN LIMITATION)
```

## Edits

| File | Action | Change | Risk |
|------|--------|--------|------|
| `android/app/build.gradle` | Modify | Remove `id "kotlin-android"` (line 3); Replace `kotlinOptions { jvmTarget = '17' }` with `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }` + import | Low — DSL supported by Kotlin 2.x |
| `android/gradle.properties` | Modify | Remove lines 8-10 (`android.builtInKotlin=false`, `android.newDsl=false`) | Low — enables built-in mode |
| `pubspec.yaml` | Modify | 5 version bumps (see E3) | Low-Medium — major bumps may have API changes |

### Order of Operations

1. **Commit 1: App-side cleanup** (E1 + E2) — `build: migrate to Flutter built-in Kotlin`
   - Remove `id "kotlin-android"` from plugins block
   - Replace `kotlinOptions` with `kotlin { compilerOptions { ... } }`
   - Remove `android.builtInKotlin=false` and `android.newDsl=false`
   - Verify: `flutter clean && flutter build apk --debug`

2. **Commit 2: Plugin upgrades** (E3) — `build: upgrade 5 plugins for Kotlin 2.2.20 compat`
   - Upgrade all 5 plugins in one commit
   - Order: audiotags (minor) → wakelock_plus → package_info_plus → share_plus → terminate_restart
   - Verify: `flutter clean && flutter build apk --debug`
   - `flutter analyze` must be 0 errors

## Plugin Upgrade Details

| Plugin | From | To | Notes |
|--------|------|----|-------|
| `audiotags` | `^1.4.1` | `^1.4.5` | Minor bump, low API risk |
| `package_info_plus` | `^8.0.0` | `^10.1.0` | Major bump (8→10); check Dart API changes |
| `share_plus` | `^10.1.4` | `^13.1.0` | Major bump (10→13); check Dart API changes |
| `wakelock_plus` | `^1.3.3` | `^1.6.1` | Major bump (1.3→1.6); low API churn |
| `terminate_restart` | git fork eb505e07 | `^1.1.0` (pub) | Drops custom fork features |

## Verification

- `flutter build apk --debug` after each commit
- `flutter analyze` — 0 errors, 0 warnings
- Grep `kotlin-android` in `android/app/build.gradle` → 0 matches
- Grep `android.builtInKotlin` in `android/gradle.properties` → 0 matches
- Build output must NOT contain "applies the Kotlin Gradle Plugin" for the **app** module
- Plugin KGP warnings are expected (upstream limitation)

## Risks and Rollback

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Major plugin version breaks Dart API | Medium | Pin to previous version, defer API migration to separate change |
| terminate_restart fork features lost | Medium | Test terminate/restart functionality after switch to pub |
| `kotlin { compilerOptions }` DSL compile error | Low | Re-add `kotlinOptions` as transitional step |
| Plugin KGP becomes error in Flutter 3.5+ | Medium (future) | Track upstream; fork/patch plugins when needed |

**Rollback**: Revert the 2 commits. Restore `android.builtInKotlin=false`.

## Estimated Changed Lines

~20 lines total (app-side: ~6 lines, plugins: ~5 lines, properties: ~2 lines)

## Open Questions

- [ ] Do `package_info_plus` 10.x and `share_plus` 13.x have Dart API breaking changes? (Check depends — not verifiable in current env)
- [ ] Does the app use any `terminate_restart` fork-only features? (Check Dart imports)
