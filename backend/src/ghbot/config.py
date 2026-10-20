from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Environment variables win over the .env file.
    model_config = SettingsConfigDict(env_file=".env")

    database_url: SecretStr
    environment: str
    dev_jwt_secret: SecretStr
