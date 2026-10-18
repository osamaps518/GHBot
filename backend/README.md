# Backend

Python 3.14, FastAPI, and uv. Run the commands below from `backend/`.

## Install and run

Install [uv](https://docs.astral.sh/uv/getting-started/installation/) (tested with
0.13.1) and Python 3.14. uv can install Python if it is missing.

```bash
uv sync --locked
cp .env.example .env
uv run --locked uvicorn ghbot.main:create_app --factory --reload
```

Open <http://127.0.0.1:8000/health> for process liveness,
<http://127.0.0.1:8000/docs> for interactive API documentation, and
<http://127.0.0.1:8000/openapi.json> for the API schema.

Start PostgreSQL 18 from the repository root with `docker compose up -d --wait`.
The API runs on the host for IDE debugging. The development database uses a named
volume. The default port is 5432, bound only to `127.0.0.1`. If it is taken, use
`POSTGRES_PORT=55432 docker compose up -d --wait` and change the port in
`backend/.env` too. The Compose credentials are for local development only.

`DATABASE_URL` is required and must use `postgresql+psycopg://` with an explicit
host and database. Environment variables override the `.env` file in the current
directory. Missing or invalid settings fail at app construction without printing
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

The test database has separate credentials, uses port 5433 (override with
`TEST_POSTGRES_PORT`), and stores data in memory. Stopping its container discards
its data. Tests require an explicit URL whose database name ends in `_test`;
never point it at development or production data. Missing or unavailable
PostgreSQL fails the integration suite. To run only HTTP/configuration checks,
use `uv run --locked pytest -m 'not integration'`.

The app owns one finite async pool (five connections, no overflow), disposed at
shutdown. `Database.session()` and the `SessionDependency` request dependency
close sessions and roll back unfinished transactions. They never commit.
Future write services must complete `async with session.begin():` before returning
success. Each concurrent task needs its own session. `expire_on_commit=False`
avoids implicit post-commit loading; fetch relationships explicitly when models
arrive. Add real domain modules when their issues introduce behavior.

## Checks

```bash
uv run --locked ruff check .
uv run --locked ruff format --check .
uv run --locked mypy
uv run --locked pytest --cov
```

Commit `pyproject.toml` and `uv.lock` together when changing dependencies.
`--locked` rejects an outdated lockfile instead of silently updating it.
