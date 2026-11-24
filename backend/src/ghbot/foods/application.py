from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import Numeric, Select, cast, desc, func, literal, or_, select, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import InstrumentedAttribute
from sqlalchemy.sql.elements import ColumnElement

from ghbot.foods.models import Food


async def changed_foods(
    session: AsyncSession, user_id: UUID, since: datetime | None
) -> list[dict[str, object]]:
    """Return distinct visible changed foods used by this trainee's diary."""
    from ghbot.food_log.models import FoodLogEntry

    used = select(FoodLogEntry.food_id).where(FoodLogEntry.user_id == user_id)
    statement = _sent_foods(user_id).where(Food.id.in_(used)).order_by(Food.id)
    if since is not None:
        statement = statement.where(Food.updated_at >= since)
    return [dict(row) for row in (await session.execute(statement)).mappings().all()]


def rounded(column: InstrumentedAttribute[float]) -> ColumnElement[Decimal]:
    """Round a stored double using PostgreSQL numeric half-up rules."""
    return func.round(cast(column, Numeric), 1)


def visible_foods(user_id: UUID) -> Select[tuple[Food]]:
    """Select catalog foods and foods owned by this trainee."""
    return select(Food).where(or_(Food.owner_id.is_(None), Food.owner_id == user_id))


def _sent_foods(
    user_id: UUID,
) -> Select[tuple[UUID, str, str | None, Decimal, Decimal, Decimal, Decimal]]:
    """Visible foods with the fields and rounding the API sends (decision 30)."""
    return visible_foods(user_id).with_only_columns(
        Food.id,
        Food.name_ar,
        Food.name_en,
        rounded(Food.calories).label("calories"),
        rounded(Food.protein).label("protein"),
        rounded(Food.carbs).label("carbs"),
        rounded(Food.fat).label("fat"),
    )


async def search_foods(
    session: AsyncSession, user_id: UUID, query: str
) -> list[dict[str, object]]:
    """Search visible foods using the same SQL cleaning as stored names."""
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
