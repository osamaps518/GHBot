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
        if "dbname" in url.query:
            raise ValueError("Specify the database in the URL path, not a dbname query")
        if url.port is not None and not 1 <= url.port <= 65535:
            raise ValueError("Database port must be between 1 and 65535")
        return value
