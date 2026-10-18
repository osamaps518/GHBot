import psycopg
import pytest
from alembic.config import Config
from alembic.script import ScriptDirectory
from sqlalchemy.engine import make_url

pytestmark = pytest.mark.integration


def test_migrations_round_trip_and_match_metadata(database_settings, alembic):
    heads = ScriptDirectory.from_config(Config("alembic.ini")).get_heads()
    assert len(heads) == 1
    url = make_url(database_settings.database_url.get_secret_value())

    with psycopg.connect(
        url.set(drivername="postgresql").render_as_string(hide_password=False),
        autocommit=True,
        connect_timeout=3,
    ) as connection:

        def current_revisions():
            return [
                row[0]
                for row in connection.execute(
                    "SELECT version_num FROM alembic_version"
                ).fetchall()
            ]

        assert current_revisions() == heads
        alembic("upgrade", "head")
        assert current_revisions() == heads
        alembic("downgrade", "base")
        assert current_revisions() == []
        alembic("upgrade", "head")
        assert current_revisions() == heads
        alembic("check")
