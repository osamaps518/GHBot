import pytest
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.exc import DBAPIError

from ghbot.database import Database, SessionDependency
from ghbot.main import create_app

pytestmark = [pytest.mark.anyio, pytest.mark.integration]


async def test_failed_work_releases_resources_for_an_independent_operation(
    database_settings,
):
    database = Database(database_settings)
    try:
        # More failures than pool slots exposes leaked sessions/connections.
        for _ in range(6):
            with pytest.raises(DBAPIError):
                async with database.session() as session:
                    await session.execute(text("SELECT 1 / 0"))

        async with database.session() as session:
            assert await session.scalar(text("SELECT 1")) == 1
    finally:
        await database.close()


async def test_session_cleanup_does_not_commit_unfinished_work(database_settings):
    database = Database(database_settings)
    try:
        async with database.session() as session:
            await session.execute(
                text("CREATE TEMP TABLE unfinished_work (id integer)")
            )

        async with database.session() as session:
            assert (
                await session.scalar(text("SELECT to_regclass('unfinished_work')"))
                is None
            )
    finally:
        await database.close()


async def test_request_sessions_recover_and_shutdown_closes_connections(
    database_settings,
):
    app = create_app(database_settings)

    @app.get("/database-probe")
    async def database_probe(session: SessionDependency, fail: bool = False):
        if fail:
            await session.execute(text("SELECT 1 / 0"))
        return {"pid": await session.scalar(text("SELECT pg_backend_pid()"))}

    async with LifespanManager(app) as manager:
        async with AsyncClient(
            transport=ASGITransport(app=manager.app, raise_app_exceptions=False),
            base_url="http://test",
        ) as client:
            for _ in range(6):
                response = await client.get("/database-probe?fail=true")
                assert response.status_code == 500
                assert response.text == "Internal Server Error"
            response = await client.get("/database-probe")
            assert response.status_code == 200
            pid = response.json()["pid"]

    observer = Database(database_settings)
    try:
        async with observer.session() as session:
            remaining = await session.scalar(
                text("SELECT count(*) FROM pg_stat_activity WHERE pid = :pid"),
                {"pid": pid},
            )
            assert remaining == 0
    finally:
        await observer.close()
