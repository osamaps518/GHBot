# Backend

Python 3.14, FastAPI, and uv. Run the commands below from `backend/`.

## Install and run

Install [uv](https://docs.astral.sh/uv/getting-started/installation/) (tested with
0.13.1) and Python 3.14. uv can install Python if it is missing.

```bash
uv sync --locked
uv run --locked uvicorn ghbot.main:create_app --factory --reload
```

Open <http://127.0.0.1:8000/health> for process liveness,
<http://127.0.0.1:8000/docs> for interactive API documentation, and
<http://127.0.0.1:8000/openapi.json> for the API schema.

## Checks

```bash
uv run --locked ruff check .
uv run --locked ruff format --check .
uv run --locked mypy
uv run --locked pytest --cov
```

Commit `pyproject.toml` and `uv.lock` together when changing dependencies.
`--locked` rejects an outdated lockfile instead of silently updating it.
