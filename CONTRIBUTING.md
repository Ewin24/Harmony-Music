# Contributing to Harmony-Music

Thank you for considering contributing! This document covers the essentials to
get started.

## Getting Started

**New contributor?** Start with the full setup guide:

👉 [`docs/setup.md`](docs/setup.md)

It walks you through installing Flutter, the Android SDK, JDK, resolving
dependencies, and running your first build. Every step has copy-paste commands
and expected outputs.

Once your environment is ready:

```bash
flutter pub get
flutter analyze
flutter build apk --debug
```

---

## Contribution Workflow

1. **Fork** the repository (or create a feature branch if you have write access)
2. **Create a branch** from `main` (or `Edwin-DEV` for active development):
   ```bash
   git checkout -b feat/your-feature-name
   ```
3. **Make your changes** — keep commits small and focused
4. **Run verification** before opening a PR:
   ```bash
   flutter analyze    # Must report 0 errors
   flutter build apk --debug   # Must succeed
   ```
5. **Open a pull request** against the `main` (or `Edwin-DEV`) branch
6. **Address review feedback** — expect constructive discussion

---

## Commit Conventions

We follow **Conventional Commits** ([conventionalcommits.org](https://www.conventionalcommits.org/)):

```
<type>(<scope>): <description>
```

Allowed types:

| Type | Usage |
|------|-------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `refactor` | Code change that neither fixes nor adds |
| `docs` | Documentation only |
| `test` | Adding or fixing tests |
| `chore` | Tooling, dependencies, config |
| `build` | Build system or CI changes |

Examples:
```
feat(player): add gapless playback
fix(auth): handle token refresh race condition
docs(setup): update Flutter SDK version
chore(deps): upgrade google_fonts to 6.3.0
```

Scopes are optional but encouraged. Keep the description imperative and concise.
Do **not** add `Co-Authored-By` or AI attribution footers.

---

## Code Style

- The project uses `analysis_options.yaml` with `flutter_lints` rules
- Run `flutter analyze` before every commit — 0 errors required
- Format your code on save (or run `dart format .`)
- Follow existing patterns in the file you're editing
- Prefer readable code over clever one-liners

---

## Pull Request Process

1. Keep PRs under **400 lines** of diff where possible
2. Link the PR to the relevant issue or SDD change
3. Include a clear description of what and why
4. If the PR changes UI, consider including a screenshot
5. A maintainer will review within a reasonable time

---

## Reporting Issues

- Use the [GitHub issue tracker](https://github.com/anandnet/Harmony-Music/issues)
- Include: Flutter version, OS, steps to reproduce, expected vs actual behavior
- Check existing issues before opening a duplicate

---

## License

Harmony-Music is licensed under **GPL v3.0** with a non-commercial clause (see
[`LICENSE`](LICENSE) or [`README.md`](README.md) for full terms). By contributing,
you agree that your contributions will be licensed under the same terms.
