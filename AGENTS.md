Rules for AI coding agents (and people) working on GHBot.

## Layout
- `backend/`: FastAPI app. One folder per module in `src/ghbot/`; a module's `__init__.py` is its public API (decision 10).
- `mobile/`: Flutter app, Android only. Folders in `lib/` mirror the backend modules; `core/` holds what they share (decision 18).
- `docs/decisions.md`: why things are the way they are. Read the entry for an area before changing it.

## Running
- Setup, run and check commands are in `backend/README.md` and `mobile/README.md`.
- Backend tests need Postgres: `docker compose up -d --wait` from the repo root.
- The app won't start without `mobile/config.json`. Use Flutter 3.47.7 exactly.

## Branches, commits and PRs
- Follow CONTRIBUTING.md: branch `<type>/<issue>-<description>`, `Closes #<issue>` in the PR, squash merge.
- PR titles look like `feat(targets): calculate daily targets`. The title becomes the commit on `main`.
- Commit in small steps, one behavior each with its tests, so the history shows what changed and why. Generated files and lockfiles go in the commit that causes them.

## Arabic first (app)
- No user-facing text in Dart. Add every string to `lib/l10n/app_ar.arb` (the template) and `app_en.arb`; commit the generated files.
- Arabic text is Modern Standard Arabic (فصحى), not a dialect.
- Use start and end, never left and right: `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start`. Plain `EdgeInsets` only when both sides are equal.
- Numbers use Western digits (1850) in both languages.
- Colors and text styles come from the theme in `lib/core/theme.dart` (decision 16).
- Check new screens in Arabic and English, light and dark.

## Scope
- Build only what the issue's "Done when" asks. If something else seems needed, ask first.
- Nothing for future issues: no empty modules, unused parameters, settings or abstractions "for later".
- Use library defaults. Change a setting only when you can say why.

## Libraries
- Before writing code that uses a language feature or library, check its docs with Context7 instead of relying on memory. Our versions may be newer than what you know: see backend/pyproject.toml and mobile/pubspec.yaml.

## Tests
- Test our behavior, not the libraries'. FastAPI, SQLAlchemy and Pydantic test themselves.
- A few tests that each protect something real beat many small ones.

## Docs
- Short and plain. Decisions go in docs/decisions.md, in the same style as existing entries.

## Before a PR
- Run the checks in the README of each part you changed (backend/README.md, mobile/README.md).
