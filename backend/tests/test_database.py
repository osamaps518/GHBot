import pytest
from sqlalchemy import text

from ghbot.database import SessionDependency
from ghbot.main import create_app


# Replaces the `app` fixture from conftest.py for the tests in this file.
@pytest.fixture
def app():
    app = create_app()

    # There's no real endpoint using the database yet, so add one for the test.
    @app.get("/db-check")
    async def db_check(session: SessionDependency) -> int:
        return await session.scalar(text("SELECT 1"))

    return app


def test_session_queries_postgres(client):
    response = client.get("/db-check")

    assert response.status_code == 200
    assert response.json() == 1
