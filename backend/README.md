# Backend

FastAPI and PostgreSQL. Run commands from `backend/` unless noted.

## Setup

You need [uv](https://docs.astral.sh/uv/getting-started/installation/) and Docker. uv installs the right Python version by itself.

```bash
docker compose up -d --wait   # from the repo root: starts Postgres
cd backend
cp .env.example .env
uv sync
uv run alembic upgrade head
uv run uvicorn ghbot.main:create_app --factory --reload
```

Then open <http://127.0.0.1:8000/docs>.

## Checks

CI runs these on every PR that changes `backend/`. The tests need Postgres running.

```bash
uv run ruff check .
uv run ruff format --check .
uv run mypy
uv run pytest --cov=ghbot
```

## Changing the database

Never change the database by hand. Instead:

1. Add or edit models (they inherit from `ghbot.database.Base`) and import them in `migrations/env.py`.
2. Run `uv run alembic revision --autogenerate -m "what changed"`.
3. Read the generated file and fix it if needed. Autogenerate misses some changes.
4. Run `uv run alembic upgrade head`.

Commit the model and its migration together.

## Dependencies

Add one with `uv add <package>` (or `uv add --dev <package>` for tools). Commit `pyproject.toml` and `uv.lock` together.
