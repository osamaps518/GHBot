import pytest
from pydantic import ValidationError

from ghbot.config import Settings
from ghbot.main import create_app


def test_missing_database_configuration_prevents_startup(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.delenv("DATABASE_URL", raising=False)

    with pytest.raises(ValidationError, match="database_url"):
        create_app()


@pytest.mark.parametrize(
    "database_url",
    [
        "not-a-url-private-password",
        "sqlite:///private-password",
        "postgresql+psycopg://user:private-password@localhost:invalid/ghbot",
        "postgresql+psycopg://user:private-password@localhost:65536/ghbot",
        "postgresql+psycopg://user:private-password@localhost:0/ghbot",
        "postgresql+psycopg://user:private-password@localhost/",
        "postgresql+psycopg://user:private-password@/ghbot",
        "postgresql+psycopg://user:private-password@localhost/ghbot_test?dbname=ghbot",
    ],
)
def test_invalid_database_configuration_fails_without_exposing_secrets(
    monkeypatch, tmp_path, database_url
):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setenv("DATABASE_URL", database_url)

    with pytest.raises(ValidationError, match="database_url") as error:
        create_app()

    assert "private-password" not in str(error.value)


def test_environment_overrides_local_configuration(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    (tmp_path / ".env").write_text("DATABASE_URL=invalid-local-value\n")
    url = "postgresql+psycopg://test:environment-secret@127.0.0.1/ghbot_test"
    monkeypatch.setenv("DATABASE_URL", url)

    settings = Settings()

    assert settings.database_url.get_secret_value() == url
    assert "environment-secret" not in repr(settings)
