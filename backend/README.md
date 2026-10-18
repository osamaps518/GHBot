# Backend

Python 3.14, FastAPI, PostgreSQL 18, and uv. Commands are run from `backend/`
unless a different directory is specified.

## Install and run

Install [uv](https://docs.astral.sh/uv/getting-started/installation/) 0.13.1 (the
version used in CI) and Docker with Compose. uv can install Python 3.14 if it is
missing. On Windows, use WSL2 for the documented asyncio/Psycopg setup.

Start PostgreSQL **from the repository root**:

```bash
docker compose up -d --wait
```

Then enter `backend/`:

```bash
uv sync --locked
cp .env.example .env
uv run --locked alembic upgrade head
uv run --locked uvicorn ghbot.main:create_app --factory --reload
```

Open <http://127.0.0.1:8000/health> for process liveness,
<http://127.0.0.1:8000/docs> for interactive API documentation, and
<http://127.0.0.1:8000/openapi.json> for the API schema.

The API runs on the host for IDE debugging. The development database uses a named
volume. The default port is 5432, bound only to `127.0.0.1`. If it is taken, use
`POSTGRES_PORT=55432 docker compose up -d --wait` and change the port in
`backend/.env` too. The Compose credentials are for local development only.

`DATABASE_URL` is required and must use `postgresql+psycopg://` with an explicit
host and database; query parameters cannot override the database name. Environment
variables override the `.env` file in the current directory. Missing or invalid
settings fail at app construction without printing
the supplied URL. Health is process liveness only: it does not query PostgreSQL,
and startup creates a lazy connection pool without requiring a live database.

## Database and tests

From the repository root, start the separate disposable test service:

```bash
docker compose --profile test up -d --wait test-db
```

Then from `backend/`:

```bash
export TEST_DATABASE_URL=postgresql+psycopg://ghbot_test:ghbot_test@127.0.0.1:5433/ghbot_test
uv run --locked pytest --cov
```

The test service has separate credentials, uses port 5433 (override with
`TEST_POSTGRES_PORT`), and stores data in memory. Stopping its container discards
its data. Tests require an explicit URL whose database name ends in `_test` and
a role with `CREATEDB` permission (the Compose test role has it). The suite creates
a uniquely named empty database, runs Alembic to head, and drops only that generated
database on teardown. It never migrates the database named in `TEST_DATABASE_URL`.
Never point this URL at development or production infrastructure. Missing or
unavailable PostgreSQL fails the integration suite. To run only HTTP/configuration
checks, use `uv run --locked pytest -m 'not integration'`.

The app owns one finite async pool (five connections, no overflow), disposed at
shutdown. `Database.session()` and the `SessionDependency` request dependency
close sessions and roll back unfinished transactions. They never commit.
Future write services must complete `async with session.begin():` before returning
success. Each concurrent task needs its own session. `expire_on_commit=False`
avoids implicit post-commit loading; fetch relationships explicitly when models
arrive. Add real domain modules when their issues introduce behavior.

## Migrations

Run migrations explicitly from `backend/`, using the same `DATABASE_URL` as the
app. Neither imports nor API startup create tables or run migrations.

```bash
uv run --locked alembic upgrade head
uv run --locked alembic current
uv run --locked alembic check
```

Revision `0001` is an empty baseline: it establishes migration history without
adding a business table. Issue #6 owns the first users table. The migration test
checks the expected single head, a repeated upgrade, downgrade to base, re-upgrade,
and metadata drift on a disposable database. This proves the wiring; later schema
issues must test their own tables, constraints, and data transformations.

When introducing a domain model:

1. Inherit from `ghbot.database.Base` in that domain's module.
2. Import the models in `migrations/env.py` so they enter the shared metadata.
3. Apply existing migrations, then run
   `uv run --locked alembic revision --autogenerate -m "Describe the schema change"`.
4. Review the generated upgrade and downgrade, including data loss and constraint
   names. Autogeneration cannot infer every intended change.
5. Run `uv run --locked ruff check --fix migrations` and
   `uv run --locked ruff format migrations`, upgrade, check metadata, and test on
   disposable PostgreSQL. Commit the model and reviewed migration together.

Do not use `Base.metadata.create_all()`, stamp revisions to bypass execution, or
edit shared database schemas manually. Run downgrades only on disposable data
during verification; future migrations may remove data.

## Checks

```bash
uv run --locked ruff check .
uv run --locked ruff format --check .
uv run --locked mypy
uv run --locked pytest --cov
```

Commit `pyproject.toml` and `uv.lock` together when changing dependencies.
`--locked` rejects an outdated lockfile instead of silently updating it.

The Backend GitHub Actions workflow runs these checks on backend PRs, pushes to
`main`, and manual dispatches. Its PostgreSQL service uses the same major version
as Compose. The full pytest run includes migration verification and prints
coverage without a minimum. mypy is strict for application code; its Pydantic
plugin understands that settings fields can be supplied by the environment.

## Troubleshooting and shutdown

- **Port already in use:** set `POSTGRES_PORT` or `TEST_POSTGRES_PORT` on the
  Compose command and update the corresponding connection URL. Separate worktrees
  can use `docker compose -p ghbot-my-worktree ...` plus different host ports to
  isolate their containers and development volumes.
- **Missing or invalid `database_url`:** run from `backend/`, copy `.env.example`
  to `.env`, and check for an overriding `DATABASE_URL` in your shell. These errors
  occur before serving requests. Never put real credentials in committed files.
- **Health succeeds but database commands fail:** health only tests the process.
  Run `docker compose ps` and `docker compose logs db` from the repository root,
  check the URL/port, and run `uv run --locked alembic upgrade head` from `backend/`.
- **Integration tests fail during setup:** start `test-db`, export
  `TEST_DATABASE_URL`, and verify its role can create databases. A separate
  generated database per run prevents collisions; test fixture resources are
  function-scoped so app, client, and sessions share the asyncio event loop.
- **Lockfile is stale:** make an intentional dependency update with `uv add` or
  `uv lock`, review `uv.lock`, and commit it with `pyproject.toml`.

Stop the API with Ctrl+C. From the repository root, `docker compose stop` keeps
development data; `docker compose --profile test stop test-db` discards the
in-memory test data. `docker compose --profile test down` removes the project's
containers and network while preserving the named development volume. Adding
`--volumes` would delete development data, so do that only for an intentional reset.
