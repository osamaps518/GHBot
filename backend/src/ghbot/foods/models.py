from datetime import datetime
from uuid import UUID, uuid7

from sqlalchemy import (
    ARRAY,
    CheckConstraint,
    Computed,
    DateTime,
    Double,
    ForeignKey,
    Index,
    Text,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from ghbot.database import Base


class Food(Base):
    __tablename__ = "foods"
    __table_args__ = (
        CheckConstraint(
            "source IN ('usda', 'open_food_facts', 'regional', 'trainee')",
            name="foods_source_allowed",
        ),
        CheckConstraint(
            "(source = 'trainee') = (owner_id IS NOT NULL) "
            "AND (source = 'trainee') = (source_id IS NULL)",
            name="foods_source_owner",
        ),
        CheckConstraint(
            "(owner_id IS NOT NULL OR name_ar IS NOT NULL) "
            "AND (owner_id IS NULL OR name_ar IS NOT NULL OR name_en IS NOT NULL)",
            name="foods_name_required",
        ),
        Index(
            "uq_foods_catalog_barcode",
            "barcode",
            unique=True,
            postgresql_where=text("owner_id IS NULL"),
        ),
        Index(
            "uq_foods_catalog_source_id",
            "source",
            "source_id",
            unique=True,
            postgresql_where=text("owner_id IS NULL"),
        ),
        Index(
            "ix_foods_search_trgm",
            "search",
            postgresql_using="gin",
            postgresql_ops={"search": "gin_trgm_ops"},
        ),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid7)
    name_ar: Mapped[str | None] = mapped_column(Text)
    name_en: Mapped[str | None] = mapped_column(Text)
    other_names: Mapped[list[str]] = mapped_column(
        ARRAY(Text), server_default=text("'{}'::text[]")
    )
    search: Mapped[str] = mapped_column(
        Text,
        Computed("food_search_names(name_ar, name_en, other_names)", persisted=True),
    )
    calories: Mapped[float] = mapped_column(Double)
    protein: Mapped[float] = mapped_column(Double)
    carbs: Mapped[float] = mapped_column(Double)
    fat: Mapped[float] = mapped_column(Double)
    units: Mapped[dict[str, float]] = mapped_column(
        JSONB, server_default=text("'{}'::jsonb")
    )
    density: Mapped[float | None] = mapped_column(Double)
    barcode: Mapped[str | None] = mapped_column(Text)
    source: Mapped[str] = mapped_column(Text)
    source_id: Mapped[str | None] = mapped_column(Text)
    owner_id: Mapped[UUID | None] = mapped_column(ForeignKey("users.id"))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
