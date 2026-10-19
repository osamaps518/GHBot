import pytest
from fastapi.testclient import TestClient

from ghbot.main import create_app


@pytest.fixture
def app():
    return create_app()


@pytest.fixture
def client(app):
    # Entering the TestClient runs the app's startup and shutdown (lifespan).
    with TestClient(app) as client:
        yield client
