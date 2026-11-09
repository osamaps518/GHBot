from datetime import UTC, date, datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, HTTPException, Response
from fastapi.exceptions import RequestValidationError
from pydantic import BaseModel, Field

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.profiles.application import read_profile, save_profile
from ghbot.profiles.exceptions import AgeOutOfRange, ProfileNotFound


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
    try:
        profile = await read_profile(session, user.id, utc_today())
    except ProfileNotFound:
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
    try:
        created = await save_profile(
            session,
            user.id,
            body.model_dump(),
            body.birth_year,
            body.birth_month,
            today,
        )
    except AgeOutOfRange as error:
        raise RequestValidationError(
            [
                {
                    "type": "age_out_of_range",
                    "loc": ("body", "birth_year"),
                    "msg": "Age must be between 18 and 100",
                    "input": error.birth_year,
                }
            ]
        )

    response.status_code = 201 if created else 200
    return body
