import pytest
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient

from ghbot.main import create_app


@pytest.fixture
def anyio_backend():
    return "asyncio"


@pytest.fixture
async def client():
    async with LifespanManager(create_app()) as manager:
        async with AsyncClient(
            transport=ASGITransport(app=manager.app), base_url="http://test"
        ) as client:
            yield client
