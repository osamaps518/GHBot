from uuid import UUID

from sqlalchemy import Float, ForeignKey, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column

from ghbot.database import Base


class Profile(Base):
    __tablename__ = "profiles"

    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), primary_key=True)
    birth_year: Mapped[int] = mapped_column(Integer)
    birth_month: Mapped[int] = mapped_column(Integer)
    sex: Mapped[str] = mapped_column(Text)
    height_cm: Mapped[float] = mapped_column(Float(53))
    weight_kg: Mapped[float] = mapped_column(Float(53))
    activity_level: Mapped[str] = mapped_column(Text)
    goal: Mapped[str] = mapped_column(Text)
