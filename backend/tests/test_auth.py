from datetime import UTC, datetime
from uuid import UUID, uuid4

import jwt
import pytest
from pydantic import ValidationError

from ghbot.main import create_app


@pytest.mark.parametrize("environment", ["production", "staging", ""])
def test_dev_auth_refuses_other_environments(monkeypatch, environment):
    monkeypatch.setenv("ENVIRONMENT", environment)

    with pytest.raises(ValueError, match="development"):
        create_app()


def test_dev_auth_requires_an_explicit_environment(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)  # Do not read the developer's .env.
    monkeypatch.delenv("ENVIRONMENT")
    monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://localhost/unused")

    with pytest.raises(ValidationError) as error:
        create_app()

    assert any(
        item["loc"] == ("environment",) and item["type"] == "missing"
        for item in error.value.errors()
    )


def test_dev_token_is_signed_and_short_lived(client):
    response = client.post("/dev/token", json={"subject": "alice"})

    assert response.status_code == 200
    assert response.json()["token_type"] == "bearer"
    claims = jwt.decode(
        response.json()["access_token"],
        "test-secret-for-dev-sign-in-only-32-bytes",
        algorithms=["HS256"],
        options={"require": ["sub", "iat", "exp"]},
    )
    assert claims["sub"] == "alice"
    assert claims["iat"] <= datetime.now(UTC).timestamp() < claims["exp"]
    assert claims["exp"] - claims["iat"] == 15 * 60


def test_valid_token_returns_our_user_id(client):
    token = client.post("/dev/token", json={"subject": str(uuid4())}).json()

    response = client.get(
        "/me", headers={"Authorization": f"Bearer {token['access_token']}"}
    )

    assert response.status_code == 200
    assert set(response.json()) == {"id"}
    assert UUID(response.json()["id"]).version == 7
