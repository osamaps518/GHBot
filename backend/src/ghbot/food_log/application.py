import logging
from typing import Any
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import Boolean, and_, func, literal_column
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.engine import Result, Row
from sqlalchemy.exc import DBAPIError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql import Executable

from ghbot.food_log.models import FoodLogEntry
from ghbot.foods import Food, visible_foods

logger = logging.getLogger(__name__)


async def _write(session: AsyncSession, statement: Executable) -> Result[Any]:
    """Execute a write while keeping rejected entry values out of logs."""
    try:
        return await session.execute(statement)
    except DBAPIError as exc:
        await session.rollback()
        logger.error("Food log write failed: %s %s", type(exc).__name__, exc.statement)
        raise HTTPException(status_code=500, detail="Food log write failed") from None


async def _stored_entry(
    session: AsyncSession, user_id: UUID, entry_id: UUID
) -> FoodLogEntry:
    """Read the unchanged row in the same transaction as the write that did nothing."""
    stored = await session.get(FoodLogEntry, entry_id)
    if stored is None:
        raise RuntimeError("Food log conflict row disappeared")
    if stored.user_id != user_id:
        raise HTTPException(status_code=409, detail="Entry belongs to another user")
    return stored


async def put_entry(
    session: AsyncSession, user_id: UUID, entry_id: UUID, values: dict[str, object]
) -> tuple[FoodLogEntry, bool]:
    """Write a newer owned entry, or return the stored row unchanged.

    The flag is true when the row was created.
    """
    food_id = values["food_id"]
    visible = await session.scalar(visible_foods(user_id).where(Food.id == food_id))
    if visible is None:
        raise HTTPException(status_code=422, detail="Food is not visible")

    statement = insert(FoodLogEntry).values(
        id=entry_id, user_id=user_id, deleted=False, **values
    )
    changes = {name: getattr(statement.excluded, name) for name in values}
    changes["updated_at"] = func.clock_timestamp()
    written: Row[tuple[FoodLogEntry, bool]] | None = (
        await _write(
            session,
            statement.on_conflict_do_update(
                index_elements=[FoodLogEntry.id],
                set_=changes,
                where=and_(
                    FoodLogEntry.user_id == user_id,
                    FoodLogEntry.deleted.is_(False),
                    FoodLogEntry.revision < statement.excluded.revision,
                ),
            ).returning(
                FoodLogEntry, literal_column("old.id IS NULL", Boolean).label("created")
            ),
        )
    ).first()
    if written is not None:
        await session.commit()
        return written[0], written[1]
    return await _stored_entry(session, user_id, entry_id), False


async def delete_entry(
    session: AsyncSession, user_id: UUID, entry_id: UUID
) -> FoodLogEntry:
    """Create a tombstone or permanently mark an owned entry deleted."""
    statement = insert(FoodLogEntry).values(
        id=entry_id, user_id=user_id, revision=0, deleted=True
    )
    result = statement.on_conflict_do_update(
        index_elements=[FoodLogEntry.id],
        set_={"deleted": True, "updated_at": func.clock_timestamp()},
        where=and_(FoodLogEntry.user_id == user_id, FoodLogEntry.deleted.is_(False)),
    ).returning(FoodLogEntry)
    stored: FoodLogEntry | None = (await _write(session, result)).scalar_one_or_none()
    if stored is not None:
        await session.commit()
        return stored
    return await _stored_entry(session, user_id, entry_id)
