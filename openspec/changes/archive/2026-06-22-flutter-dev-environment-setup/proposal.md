# Proposal: Flutter Dev Environment Setup

## Intent

Harmony-Music cannot build, run, or verify locally — Flutter SDK is not installed,
`.flutter` submodule is empty, and custom git-pinned forks may not resolve. Every
future SDD change depends on a working toolchain. Without it, changes are
unverifiable.

## Scope

### In Scope
- Flutter SDK 3.24.2 install path (official archive, Windows)
- `.flutter` submodule resolution (init + update or documented workaround)
- Dependency resolution: `flutter pub get` with custom forks
- First successful build: `flutter build apk --debug`
- Linter: `flutter analyze` baseline passes
- `CONTRIBUTING.md` covering setup, build, smoke commands, known issues
- `.vscode/settings.json` for Flutter tooling

### Out of Scope
- Tests (separate change)
- UI or feature work
- Dependency upgrades beyond building
- CI pipeline changes
- Desktop build targets (Windows/Linux)

## Capabilities

### New Capabilities
- `dev-environment-setup`: Flutter SDK install, dependency resolution, build
  verification, and contributor setup documentation

### Modified Capabilities
None — no existing specs to modify.

## Approach

1. Install Flutter 3.24.2 from `docs.flutter.dev/get-started/install/windows`
2. Add to PATH, run `flutter doctor` to verify
3. Resolve `.flutter` submodule: `git submodule update --init` or document manual
   clone if submodule config is broken
4. Run `flutter pub get` — verify custom fork resolution
5. Run `flutter analyze` — capture baseline
6. Run `flutter build apk --debug` — verify Android APK output
7. Write `CONTRIBUTING.md` — setup steps, build commands, common errors
8. Add `.vscode/settings.json` with Flutter-recommended configuration

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `.flutter/` | Modified | Submodule init/update |
| `CONTRIBUTING.md` | New | Contributor setup guide |
| `.vscode/settings.json` | New | Workspace editor config |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Flutter SDK ~1.5GB download | High | Document size up front |
| Custom fork pub resolution fails | Medium | Pin known-working commit SHAs |
| Android SDK not in PATH | High | `flutter doctor` surfaces; document SDK setup |
| `.flutter` submodule broken | Medium | Document manual clone workaround |

## Rollback Plan

Remove Flutter from PATH, delete `CONTRIBUTING.md` and `.vscode/settings.json`,
restore `.flutter` via `git checkout -- .flutter`.

## Dependencies

- Flutter SDK 3.24.2 archive (~1.5GB download)
- Android SDK (for `build apk` target)
- Git submodule access or manual fork clone

## Success Criteria

- [ ] `flutter doctor` reports no blocking issues
- [ ] `flutter pub get` resolves all dependencies
- [ ] `flutter analyze` passes with 0 errors
- [ ] `flutter build apk --debug` produces a valid APK
- [ ] `CONTRIBUTING.md` covers full setup, build, and common issues
- [ ] New contributor can reproduce the above steps from docs alone
