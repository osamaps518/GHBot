from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from ghbot.config import Settings


class Base(DeclarativeBase):
    """Shared metadata for domain models as their features are introduced."""


class Database:
    def __init__(self, settings: Settings) -> None:
        self._engine = create_async_engine(
            settings.database_url.get_secret_value(),
            pool_size=5,
            max_overflow=0,
            pool_timeout=5,
            pool_pre_ping=True,
            hide_parameters=True,
            connect_args={"connect_timeout": 3},
        )
        self._sessions = async_sessionmaker(self._engine, expire_on_commit=False)

    @asynccontextmanager
    async def session(self) -> AsyncIterator[AsyncSession]:
        """Supply one session; close and roll back unfinished work, never commit."""
        async with self._sessions() as session:
            yield session

    async def close(self) -> None:
        await self._engine.dispose()


async def get_session(request: Request) -> AsyncIterator[AsyncSession]:
    database: Database = request.state.database
    async with database.session() as session:
        yield session


SessionDependency = Annotated[AsyncSession, Depends(get_session, scope="function")]
