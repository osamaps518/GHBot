from pydantic import SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import make_url
from sqlalchemy.exc import ArgumentError


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", hide_input_in_errors=True
    )

    database_url: SecretStr

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, value: SecretStr) -> SecretStr:
        message = "Use a postgresql+psycopg URL with an explicit host and database"
        try:
            url = make_url(value.get_secret_value())
        except ArgumentError, ValueError:
            raise ValueError(message) from None
        if url.drivername != "postgresql+psycopg" or not url.host or not url.database:
            raise ValueError(message)
        return value
