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
