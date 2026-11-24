from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Numeric, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from ghbot.database import Base

VALUE_COLUMNS = (
    "food_id",
    "meal",
    "diary_day",
    "grams",
    "logged_at",
    "calories_per_100g",
    "protein_per_100g",
    "carbs_per_100g",
    "fat_per_100g",
    "calories",
    "protein",
    "carbs",
    "fat",
)


class FoodLogEntry(Base):
    __tablename__ = "food_log_entries"
    __table_args__ = (
        Index("ix_food_log_entries_user_updated", "user_id", "updated_at"),
        CheckConstraint("revision >= 0", name="food_log_revision_nonnegative"),
        CheckConstraint(
            "meal IS NULL OR meal IN ('breakfast', 'lunch', 'dinner', 'extra')",
            name="food_log_meal_allowed",
        ),
        CheckConstraint(
            "deleted OR (revision >= 1 AND "
            + " AND ".join(f"{name} IS NOT NULL" for name in VALUE_COLUMNS)
            + ")",
            name="food_log_active_values",
        ),
        CheckConstraint(
            "(meal = 'extra' AND meal_name IS NOT NULL AND "
            "length(trim(meal_name)) BETWEEN 1 AND 40) OR "
            "(meal IS DISTINCT FROM 'extra' AND meal_name IS NULL)",
            name="food_log_meal_name",
        ),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    food_id: Mapped[UUID | None] = mapped_column(ForeignKey("foods.id"))
    meal: Mapped[str | None] = mapped_column(Text)
    meal_name: Mapped[str | None] = mapped_column(Text)
    diary_day: Mapped[date | None]
    grams: Mapped[Decimal | None] = mapped_column(Numeric(10, 1))
    logged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    calories_per_100g: Mapped[Decimal | None] = mapped_column(Numeric(10, 1))
    protein_per_100g: Mapped[Decimal | None] = mapped_column(Numeric(10, 1))
    carbs_per_100g: Mapped[Decimal | None] = mapped_column(Numeric(10, 1))
    fat_per_100g: Mapped[Decimal | None] = mapped_column(Numeric(10, 1))
    calories: Mapped[Decimal | None] = mapped_column(Numeric(10, 1))
    protein: Mapped[Decimal | None] = mapped_column(Numeric(10, 1))
    carbs: Mapped[Decimal | None] = mapped_column(Numeric(10, 1))
    fat: Mapped[Decimal | None] = mapped_column(Numeric(10, 1))
    revision: Mapped[int]
    deleted: Mapped[bool]
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.clock_timestamp()
    )
