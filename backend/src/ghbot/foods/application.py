from uuid import UUID

from sqlalchemy import Select, or_, select

from ghbot.foods.models import Food


def visible_foods(user_id: UUID) -> Select[tuple[Food]]:
    """Select catalog foods and foods owned by this trainee."""
    return select(Food).where(or_(Food.owner_id.is_(None), Food.owner_id == user_id))
