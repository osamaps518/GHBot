import logging
from datetime import datetime
from typing import Any, cast
from uuid import UUID

from sqlalchemy import Boolean, and_, func, literal_column, select, text
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.engine import Result, Row
from sqlalchemy.exc import DBAPIError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql import Executable

from ghbot.food_log.exceptions import (
    EntryOfAnotherUser,
    EntryWriteFailed,
    FoodNotVisible,
)
from ghbot.food_log.models import FoodLogEntry
from ghbot.foods import Food, changed_foods, visible_foods

logger = logging.getLogger(__name__)


async def pull_changes(
    session: AsyncSession, user_id: UUID, since: datetime | None
) -> tuple[datetime, list[FoodLogEntry], list[dict[str, object]]]:
    """Take the overlapping marker before reading entries and their used foods."""
    marker = await _pull_marker(session)
    entries = await _pull_entries(session, user_id, since)
    used = select(FoodLogEntry.food_id).where(FoodLogEntry.user_id == user_id)
    pulled = {entry.food_id for entry in entries if entry.food_id is not None}
    foods = await changed_foods(session, user_id, since, used, pulled)
    return marker, entries, foods


async def _pull_marker(session: AsyncSession) -> datetime:
    """Reserve an overlapping database-time marker before reading changes."""
    marker = await session.scalar(
        select(func.clock_timestamp() - text("interval '30 seconds'"))
    )
    if marker is None:
        raise RuntimeError("Database did not return a pull marker")
    return cast(datetime, marker)


async def _pull_entries(
    session: AsyncSession, user_id: UUID, since: datetime | None
) -> list[FoodLogEntry]:
    """Return this trainee's changed rows, including tombstones."""
    statement = select(FoodLogEntry).where(FoodLogEntry.user_id == user_id)
    if since is not None:
        statement = statement.where(FoodLogEntry.updated_at >= since)
    statement = statement.order_by(FoodLogEntry.updated_at, FoodLogEntry.id)
    return list((await session.scalars(statement)).all())


async def _write(session: AsyncSession, statement: Executable) -> Result[Any]:
    """Execute a write while keeping rejected entry values out of logs."""
    try:
        return await session.execute(statement)
    except DBAPIError as exc:
        await session.rollback()
        logger.error("Food log write failed: %s %s", type(exc).__name__, exc.statement)
        raise EntryWriteFailed from None


async def _stored_entry(
    session: AsyncSession, user_id: UUID, entry_id: UUID
) -> FoodLogEntry:
    """Read the unchanged row in the same transaction as the write that did nothing."""
    stored = await session.get(FoodLogEntry, entry_id)
    if stored is None:
        raise RuntimeError("Food log conflict row disappeared")
    if stored.user_id != user_id:
        raise EntryOfAnotherUser
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
        raise FoodNotVisible

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
