Rules for AI coding agents working on GHBot.

## Scope
- Build only what the issue's "Done when" asks. If something else seems needed, ask first.
- Nothing for future issues: no empty modules, unused parameters, settings or abstractions "for later".
- Use library defaults. Change a setting only when you can say why.

## Tests
- Test our behavior, not the libraries'. FastAPI, SQLAlchemy and Pydantic test themselves.
- A few tests that each protect something real beat many small ones.

## Docs
- Short and plain. Decisions go in docs/decisions.md, in the same style as existing entries.

## Before a PR
- Run the checks in backend/README.md.
