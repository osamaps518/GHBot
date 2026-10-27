from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.profiles import Profile, age_on_date, utc_today
from ghbot.targets.calculation import Targets, calculate_targets

router = APIRouter(prefix="/me/targets")


@router.get("")
async def get_targets(
    user: CurrentUser,
    session: SessionDependency,
    today: Annotated[date, Depends(utc_today)],
) -> Targets:
    profile = await session.get(Profile, user.id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    return calculate_targets(
        profile.sex,
        age_on_date(profile.birth_year, profile.birth_month, today),
        profile.weight_kg,
        profile.height_cm,
        profile.activity_level,
        profile.goal,
    )
