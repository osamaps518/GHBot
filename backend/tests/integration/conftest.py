import os
import subprocess
import sys
from functools import partial
from pathlib import Path
from uuid import uuid4

import psycopg
import pytest
from psycopg import sql
from sqlalchemy.engine import make_url

from ghbot.config import Settings

BACKEND_ROOT = Path(__file__).resolve().parents[2]


def run_alembic(settings, *arguments):
    result = subprocess.run(
        [sys.executable, "-m", "alembic", *arguments],
        cwd=BACKEND_ROOT,
        env={**os.environ, "DATABASE_URL": settings.database_url.get_secret_value()},
        capture_output=True,
        text=True,
        timeout=30,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    return result.stdout


@pytest.fixture(scope="session")
def database_settings():
    url = os.environ.get("TEST_DATABASE_URL")
    if not url:
        pytest.fail("Set TEST_DATABASE_URL to a disposable PostgreSQL database")
    Settings(_env_file=None, database_url=url)
    parsed = make_url(url)
    if not parsed.database.endswith("_test"):
        pytest.fail("TEST_DATABASE_URL must name a disposable database ending in _test")
    database_name = f"ghbot_{uuid4().hex}_test"
    admin_url = parsed.set(drivername="postgresql").render_as_string(
        hide_password=False
    )
    try:
        admin = psycopg.connect(admin_url, autocommit=True, connect_timeout=3)
    except psycopg.OperationalError:
        pytest.fail(
            "PostgreSQL is unavailable; start test-db and check TEST_DATABASE_URL"
        )

    with admin:
        admin.execute(
            sql.SQL("CREATE DATABASE {}").format(sql.Identifier(database_name))
        )
        try:
            settings = Settings(
                _env_file=None,
                database_url=parsed.set(database=database_name).render_as_string(
                    hide_password=False
                ),
            )
            run_alembic(settings, "upgrade", "head")
            yield settings
        finally:
            admin.execute(
                sql.SQL("DROP DATABASE {} WITH (FORCE)").format(
                    sql.Identifier(database_name)
                )
            )


@pytest.fixture
def alembic(database_settings):
    return partial(run_alembic, database_settings)
