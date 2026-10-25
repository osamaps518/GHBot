import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy import Connection
from sqlalchemy.ext.asyncio import create_async_engine

from ghbot.auth import models  # noqa: F401 -- register the users table for Alembic
from ghbot.config import Settings
from ghbot.database import Base
from ghbot.profiles import models as profile_models  # noqa: F401 -- register profiles

target_metadata = Base.metadata

if context.config.config_file_name is not None:
    fileConfig(context.config.config_file_name)


def run_migrations(connection: Connection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def main() -> None:
    engine = create_async_engine(Settings().database_url.get_secret_value())
    async with engine.connect() as connection:
        # Alembic's migration API is synchronous; run_sync bridges it.
        await connection.run_sync(run_migrations)
    await engine.dispose()


asyncio.run(main())
