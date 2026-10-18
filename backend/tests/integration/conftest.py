import os

import pytest
from sqlalchemy.engine import make_url

from ghbot.config import Settings


@pytest.fixture(scope="session")
def database_settings():
    url = os.environ.get("TEST_DATABASE_URL")
    if not url:
        pytest.fail("Set TEST_DATABASE_URL to a disposable PostgreSQL database")
    settings = Settings(_env_file=None, database_url=url)
    if not make_url(url).database.endswith("_test"):
        pytest.fail("TEST_DATABASE_URL must name a disposable database ending in _test")
    return settings
