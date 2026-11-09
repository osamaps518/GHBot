from calendar import monthrange
from dataclasses import dataclass
from datetime import date
from typing import cast
from uuid import UUID

from sqlalchemy import update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from ghbot.profiles.exceptions import AgeOutOfRange, ProfileNotFound
from ghbot.profiles.models import ActivityLevel, Goal, Profile, Sex


@dataclass(frozen=True)
class ProfileSnapshot:
    birth_year: int
    birth_month: int
    sex: Sex
    height_cm: float
    weight_kg: float
    activity_level: ActivityLevel
    goal: Goal
    age: int


def age_on_date(birth_year: int, birth_month: int, today: date) -> int:
    last_day = monthrange(today.year, birth_month)[1]
    return (
        today.year - birth_year - ((today.month, today.day) < (birth_month, last_day))
    )


async def read_profile(
    session: AsyncSession, user_id: UUID, today: date
) -> ProfileSnapshot:
    row = await session.get(Profile, user_id)
    if row is None:
        raise ProfileNotFound
    return ProfileSnapshot(
        birth_year=row.birth_year,
        birth_month=row.birth_month,
        sex=cast(Sex, row.sex),
        height_cm=row.height_cm,
        weight_kg=row.weight_kg,
        activity_level=cast(ActivityLevel, row.activity_level),
        goal=cast(Goal, row.goal),
        age=age_on_date(row.birth_year, row.birth_month, today),
    )


async def save_profile(
    session: AsyncSession,
    user_id: UUID,
    values: dict[str, object],
    birth_year: int,
    birth_month: int,
    today: date,
) -> bool:
    age = age_on_date(birth_year, birth_month, today)
    if not 18 <= age <= 100:
        raise AgeOutOfRange(birth_year)

    created = await session.scalar(
        insert(Profile)
        .values(user_id=user_id, **values)
        .on_conflict_do_nothing(index_elements=[Profile.user_id])
        .returning(Profile.user_id)
    )
    if created is None:
        await session.execute(
            update(Profile).where(Profile.user_id == user_id).values(**values)
        )
    await session.commit()
    return created is not None
