from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Parent class of every ORM model, so Alembic can see their tables."""


async def get_session(request: Request) -> AsyncIterator[AsyncSession]:
    # One session per request. Closing it rolls back anything not committed,
    # so code that writes data must commit explicitly.
    async with request.state.sessions() as session:
        yield session


SessionDependency = Annotated[AsyncSession, Depends(get_session)]
