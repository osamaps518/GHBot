import os
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime
from threading import Barrier
from uuid import UUID, uuid4

import jwt
import pytest
from pydantic import ValidationError

from ghbot.main import create_app


def auth_headers(client, subject):
    token = client.post("/dev/token", json={"subject": subject}).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


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


def test_dev_auth_rejects_an_empty_secret(monkeypatch):
    monkeypatch.setenv("DEV_JWT_SECRET", "")

    with pytest.raises(ValidationError):
        create_app()


def test_dev_token_is_signed_and_short_lived(client):
    response = client.post("/dev/token", json={"subject": "alice"})

    assert response.status_code == 200
    assert response.json()["token_type"] == "bearer"
    claims = jwt.decode(
        response.json()["access_token"],
        os.environ["DEV_JWT_SECRET"],
        algorithms=["HS256"],
        options={"require": ["sub", "iat", "exp"]},
    )
    assert claims["sub"] == "alice"
    assert claims["iat"] <= datetime.now(UTC).timestamp() < claims["exp"]
    assert claims["exp"] - claims["iat"] == 15 * 60


@pytest.mark.parametrize("subject", ["", "a\x00b", "x" * 3000])
def test_dev_token_rejects_invalid_subjects(client, subject):
    response = client.post("/dev/token", json={"subject": subject})

    assert response.status_code == 422


def test_valid_token_returns_our_user_id(client):
    response = client.get("/me", headers=auth_headers(client, str(uuid4())))

    assert response.status_code == 200
    assert set(response.json()) == {"id"}
    assert UUID(response.json()["id"]).version == 7


@pytest.mark.parametrize(
    "invalid", ["missing", "not-a-jwt", "expired", "wrong-signature", "missing-expiry"]
)
def test_invalid_credentials_get_the_same_401(client, invalid):
    if invalid == "missing":
        headers = {}
    elif invalid == "not-a-jwt":
        headers = {"Authorization": "Bearer not-a-jwt"}
    else:
        now = int(datetime.now(UTC).timestamp())
        claims = {"sub": str(uuid4()), "iat": now, "exp": now + 900}
        secret = os.environ["DEV_JWT_SECRET"]
        if invalid == "expired":
            claims["exp"] = now - 1
        elif invalid == "wrong-signature":
            secret = "different-secret-for-dev-sign-in-only-32-bytes"
        else:
            del claims["exp"]
        token = jwt.encode(claims, secret, algorithm="HS256")
        headers = {"Authorization": f"Bearer {token}"}

    response = client.get("/me", headers=headers)

    assert response.status_code == 401
    assert response.json() == {"detail": "Not authenticated"}
    assert response.headers["WWW-Authenticate"] == "Bearer"


def test_subject_keeps_its_user_id_across_requests(client):
    headers = auth_headers(client, str(uuid4()))
    first = client.get("/me", headers=headers)
    returning = client.get("/me", headers=headers)

    assert first.status_code == returning.status_code == 200
    assert returning.json()["id"] == first.json()["id"]

    other = client.get("/me", headers=auth_headers(client, str(uuid4())))
    assert other.status_code == 200
    assert other.json()["id"] != first.json()["id"]


def test_concurrent_first_requests_share_one_user(client):
    headers = auth_headers(client, str(uuid4()))
    start = Barrier(4)

    def get_me():
        start.wait(timeout=10)
        return client.get("/me", headers=headers)

    with ThreadPoolExecutor(max_workers=4) as pool:
        futures = [pool.submit(get_me) for _ in range(4)]
        responses = [future.result(timeout=10) for future in futures]

    assert all(response.status_code == 200 for response in responses)
    assert len({response.json()["id"] for response in responses}) == 1
