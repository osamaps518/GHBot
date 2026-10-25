from calendar import monthrange
from datetime import UTC, date, datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel, Field
from sqlalchemy import update
from sqlalchemy.dialects.postgresql import insert

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.profiles.models import Profile


class ProfileBody(BaseModel):
    birth_year: int
    birth_month: int = Field(ge=1, le=12)
    sex: Literal["male", "female"]
    height_cm: float = Field(ge=130, le=220)
    weight_kg: float = Field(ge=35, le=250)
    activity_level: Literal[
        "sedentary",
        "lightly_active",
        "moderately_active",
        "very_active",
        "extremely_active",
    ]
    goal: Literal["lose", "maintain", "gain"]


router = APIRouter(prefix="/me/profile")


def utc_today() -> date:
    return datetime.now(UTC).date()


@router.get("")
async def get_profile(user: CurrentUser, session: SessionDependency) -> ProfileBody:
    profile = await session.get(Profile, user.id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    return ProfileBody.model_validate(profile, from_attributes=True)


@router.put("")
async def put_profile(
    body: ProfileBody,
    user: CurrentUser,
    session: SessionDependency,
    response: Response,
    today: Annotated[date, Depends(utc_today)],
) -> ProfileBody:
    last_day = monthrange(today.year, body.birth_month)[1]
    age = (
        today.year
        - body.birth_year
        - ((today.month, today.day) < (body.birth_month, last_day))
    )
    if not 18 <= age <= 80:
        raise HTTPException(status_code=422, detail="Age must be between 18 and 80")

    values = body.model_dump()
    created = await session.scalar(
        insert(Profile)
        .values(user_id=user.id, **values)
        .on_conflict_do_nothing(index_elements=[Profile.user_id])
        .returning(Profile.user_id)
    )
    if created is None:
        await session.execute(
            update(Profile).where(Profile.user_id == user.id).values(**values)
        )
    await session.commit()
    response.status_code = 201 if created is not None else 200
    return body
