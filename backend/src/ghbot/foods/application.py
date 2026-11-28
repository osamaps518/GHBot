from collections.abc import Collection
from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import (
    Boolean,
    Numeric,
    Select,
    and_,
    cast,
    desc,
    func,
    literal,
    literal_column,
    or_,
    select,
    text,
)
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import InstrumentedAttribute
from sqlalchemy.sql.elements import ColumnElement

from ghbot.foods.models import Food


class FoodOfAnotherUser(Exception):
    """The food ID belongs to a catalog row or another trainee."""


async def put_own_food(
    session: AsyncSession, user_id: UUID, food_id: UUID, values: dict[str, object]
) -> tuple[dict[str, object], bool]:
    """Create an owned food or replace it at a higher revision (decision 31).

    Return the stored food and whether this call created it. A conflicting ID
    outside the caller's ownership raises FoodOfAnotherUser.
    """
    statement = insert(Food).values(
        id=food_id,
        owner_id=user_id,
        source="trainee",
        updated_at=func.clock_timestamp(),
        **values,
    )
    changes = {name: getattr(statement.excluded, name) for name in values}
    changes["updated_at"] = func.clock_timestamp()
    written = (
        (
            await session.execute(
                statement.on_conflict_do_update(
                    index_elements=[Food.id],
                    set_=changes,
                    where=and_(
                        Food.owner_id == user_id,
                        Food.revision < statement.excluded.revision,
                    ),
                ).returning(
                    *_SENT_COLUMNS,
                    literal_column("old.id IS NULL", Boolean).label("created"),
                )
            )
        )
        .mappings()
        .first()
    )
    if written is not None:
        await session.commit()
        answer = dict(written)
        return answer, bool(answer.pop("created"))
    stored = (
        (
            await session.execute(
                select(*_SENT_COLUMNS, Food.owner_id).where(Food.id == food_id)
            )
        )
        .mappings()
        .first()
    )
    if stored is None:
        raise RuntimeError("Food conflict row disappeared")
    answer = dict(stored)
    if answer.pop("owner_id") != user_id:
        raise FoodOfAnotherUser
    return answer, False


async def changed_foods(
    session: AsyncSession,
    user_id: UUID,
    since: datetime | None,
    used: Select[tuple[UUID | None]],
    pulled: Collection[UUID],
) -> list[dict[str, object]]:
    """Return distinct visible foods for a pull of this trainee's diary.

    These are its own foods and used foods changed since the marker, plus the
    foods in `pulled`, those of the entries returned, changed or not
    (decision 31). They are ordered by ID.
    """
    statement = (
        _sent_foods(user_id)
        .where(or_(Food.id.in_(used), Food.owner_id == user_id))
        .order_by(Food.id)
    )
    if since is not None:
        statement = statement.where(or_(Food.updated_at >= since, Food.id.in_(pulled)))
    return [dict(row) for row in (await session.execute(statement)).mappings().all()]


def rounded(column: InstrumentedAttribute[float]) -> ColumnElement[Decimal]:
    """Round a stored double using PostgreSQL numeric half-up rules."""
    return func.round(cast(column, Numeric), 1)


def visible_foods(user_id: UUID) -> Select[tuple[Food]]:
    """Select catalog foods and foods owned by this trainee."""
    return select(Food).where(or_(Food.owner_id.is_(None), Food.owner_id == user_id))


_SENT_COLUMNS = (
    Food.id,
    Food.name_ar,
    Food.name_en,
    rounded(Food.calories).label("calories"),
    rounded(Food.protein).label("protein"),
    rounded(Food.carbs).label("carbs"),
    rounded(Food.fat).label("fat"),
    Food.barcode,
    Food.owner_id.is_not(None).label("own"),
    Food.revision,
)
"""A food's fields as the API sends them, with the rounding of decision 30."""


def _sent_foods(user_id: UUID) -> Select[tuple[object, ...]]:
    """Visible foods with the fields and rounding the API sends (decision 30)."""
    return visible_foods(user_id).with_only_columns(*_SENT_COLUMNS)


async def search_foods(
    session: AsyncSession, user_id: UUID, query: str
) -> list[dict[str, object]]:
    """Search visible foods using the same SQL cleaning as stored names.

    A food's `search` text is its cleaned names joined with " | ", so a name
    that begins with the query starts the text or follows " | ". Cleaning
    leaves pipes unchanged.
    """
    cleaned = await session.scalar(select(func.food_search_clean(query)))
    if not cleaned:
        return []

    await session.execute(text("SET LOCAL pg_trgm.word_similarity_threshold = 0.5"))
    escaped = cleaned.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    contains = Food.search.ilike(f"%{escaped}%", escape="\\")
    starts = or_(
        Food.search.ilike(f"{escaped}%", escape="\\"),
        Food.search.ilike(f"% | {escaped}%", escape="\\"),
    )
    score = func.word_similarity(cleaned, Food.search)
    statement = (
        _sent_foods(user_id)
        .where(or_(contains, literal(cleaned).op("<%")(Food.search)))
        .order_by(desc(Food.owner_id.is_not(None)), desc(starts), desc(score), Food.id)
        .limit(20)
    )
    rows = (await session.execute(statement)).mappings().all()
    return [dict(row) for row in rows]
