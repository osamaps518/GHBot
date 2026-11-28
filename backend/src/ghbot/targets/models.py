from datetime import date, datetime
from uuid import UUID, uuid7

from sqlalchemy import DateTime, ForeignKey, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from ghbot.database import Base


class CustomTargets(Base):
    __tablename__ = "custom_targets"

    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), primary_key=True)
    calories: Mapped[int]
    protein_g: Mapped[int]
    fat_g: Mapped[int]
    carbs_g: Mapped[int]
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.clock_timestamp()
    )


class TargetHistory(Base):
    __tablename__ = "target_history"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid7)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    kind: Mapped[str] = mapped_column(Text)
    date: Mapped[date]
    recommended_calories: Mapped[int]
    recommended_protein_g: Mapped[int]
    recommended_fat_g: Mapped[int]
    recommended_carbs_g: Mapped[int]
    custom_calories: Mapped[int]
    custom_protein_g: Mapped[int]
    custom_fat_g: Mapped[int]
    custom_carbs_g: Mapped[int]
