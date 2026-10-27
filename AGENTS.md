Rules for AI coding agents working on GHBot.

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
