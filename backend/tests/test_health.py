import pytest
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.exc import OperationalError

from ghbot.database import SessionDependency
from ghbot.main import create_app


@pytest.mark.anyio
async def test_health_reports_a_running_process(client):
    response = await client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


@pytest.mark.anyio
async def test_public_docs_and_openapi_describe_health(client):
    docs = await client.get("/docs")
    schema = await client.get("/openapi.json")

    assert docs.status_code == 200
    assert docs.headers["content-type"].startswith("text/html")
    assert schema.status_code == 200
    assert "get" in schema.json()["paths"]["/health"]


@pytest.mark.anyio
async def test_database_outage_does_not_stop_process_health(settings):
    app = create_app(settings)

    # Test-only route exercises the real request dependency; no business API needed.
    @app.get("/database-probe")
    async def database_probe(session: SessionDependency):
        return {"value": await session.scalar(text("SELECT 1"))}

    async with LifespanManager(app) as manager:
        async with AsyncClient(
            transport=ASGITransport(app=manager.app), base_url="http://test"
        ) as client:
            with pytest.raises(OperationalError):
                await client.get("/database-probe")

        async with AsyncClient(
            transport=ASGITransport(app=manager.app, raise_app_exceptions=False),
            base_url="http://test",
        ) as client:
            unavailable = await client.get("/database-probe")
            health = await client.get("/health")

    assert unavailable.status_code == 500
    assert unavailable.text == "Internal Server Error"
    assert health.status_code == 200
    assert health.json() == {"status": "ok"}
