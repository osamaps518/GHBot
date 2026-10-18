import pytest
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient

from ghbot.config import Settings
from ghbot.main import create_app


@pytest.fixture
def anyio_backend():
    return "asyncio"


@pytest.fixture
def settings():
    return Settings(
        _env_file=None,
        database_url="postgresql+psycopg://test:test@127.0.0.1:1/ghbot_test",
    )


@pytest.fixture
async def client(settings):
    async with LifespanManager(create_app(settings)) as manager:
        async with AsyncClient(
            transport=ASGITransport(app=manager.app), base_url="http://test"
        ) as client:
            yield client
