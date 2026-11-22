import logging
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import Boolean, and_, func, literal_column
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.engine import Row
from sqlalchemy.exc import DBAPIError
from sqlalchemy.ext.asyncio import AsyncSession

from ghbot.food_log.models import FoodLogEntry
from ghbot.foods import Food, visible_foods

logger = logging.getLogger(__name__)


async def put_entry(
    session: AsyncSession, user_id: UUID, entry_id: UUID, values: dict[str, object]
) -> tuple[FoodLogEntry, bool]:
    """Write a newer owned entry, or return the stored row unchanged."""
    food_id = values["food_id"]
    visible = await session.scalar(visible_foods(user_id).where(Food.id == food_id))
    if visible is None:
        raise HTTPException(status_code=422, detail="Food is not visible")

    statement = insert(FoodLogEntry).values(
        id=entry_id, user_id=user_id, deleted=False, **values
    )
    changes = {name: getattr(statement.excluded, name) for name in values}
    changes["updated_at"] = func.clock_timestamp()
    try:
        written: Row[tuple[FoodLogEntry, bool]] | None = (
            await session.execute(
                statement.on_conflict_do_update(
                    index_elements=[FoodLogEntry.id],
                    set_=changes,
                    where=and_(
                        FoodLogEntry.user_id == user_id,
                        FoodLogEntry.deleted.is_(False),
                        FoodLogEntry.revision < statement.excluded.revision,
                    ),
                ).returning(FoodLogEntry, literal_column("(xmax = 0)", Boolean).label("created"))
            )
        ).first()
    except DBAPIError as exc:
        await session.rollback()
        logger.error("Food log write failed: %s %s", type(exc).__name__, exc.statement)
        raise HTTPException(status_code=500, detail="Food log write failed") from None
    if written is not None:
        await session.commit()
        return written[0], written[1]
    stored = await session.get(FoodLogEntry, entry_id)
    if stored is None:
        raise RuntimeError("Food log conflict row disappeared")
    if stored.user_id != user_id:
        raise HTTPException(status_code=409, detail="Entry belongs to another user")
    return stored, False


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
    try:
        stored = await session.scalar(result)
    except DBAPIError as exc:
        await session.rollback()
        logger.error("Food log write failed: %s %s", type(exc).__name__, exc.statement)
        raise HTTPException(status_code=500, detail="Food log write failed") from None
    if stored is not None:
        await session.commit()
        return stored
    stored = await session.get(FoodLogEntry, entry_id)
    if stored is None:
        raise RuntimeError("Food log conflict row disappeared")
    if stored.user_id != user_id:
        raise HTTPException(status_code=409, detail="Entry belongs to another user")
    return stored
