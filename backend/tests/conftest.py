import pytest
from fastapi.testclient import TestClient

from ghbot.main import create_app


@pytest.fixture
def auth_headers(client):
    def headers(subject):
        token = client.post("/dev/token", json={"subject": subject}).json()[
            "access_token"
        ]
        return {"Authorization": f"Bearer {token}"}

    return headers


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
