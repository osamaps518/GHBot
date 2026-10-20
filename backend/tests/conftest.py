import pytest
from fastapi.testclient import TestClient

from ghbot.main import create_app


@pytest.fixture(autouse=True)
def development_environment(monkeypatch):
    monkeypatch.setenv("ENVIRONMENT", "development")
    monkeypatch.setenv("DEV_JWT_SECRET", "test-secret-for-dev-sign-in-only-32-bytes")


@pytest.fixture
def app():
    return create_app()


@pytest.fixture
def client(app):
    # Entering the TestClient runs the app's startup and shutdown (lifespan).
    with TestClient(app) as client:
        yield client
