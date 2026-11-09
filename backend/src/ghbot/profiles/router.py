from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Response
from fastapi.exceptions import RequestValidationError
from pydantic import BaseModel, Field

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.profiles.application import save_profile
from ghbot.profiles.dependencies import SavedProfile, utc_today
from ghbot.profiles.exceptions import AgeOutOfRange
from ghbot.profiles.models import ActivityLevel, Goal, Sex


class ProfileBody(BaseModel):
    birth_year: int
    birth_month: int = Field(ge=1, le=12)
    sex: Sex
    height_cm: float = Field(ge=130, le=220)
    weight_kg: float = Field(ge=35, le=250)
    activity_level: ActivityLevel
    goal: Goal


class ProfileResponse(BaseModel):
    birth_year: int
    birth_month: int
    sex: str
    height_cm: float
    weight_kg: float
    activity_level: str
    goal: str


router = APIRouter(prefix="/me/profile")


@router.get("")
async def get_profile(profile: SavedProfile) -> ProfileResponse:
    return ProfileResponse.model_validate(profile, from_attributes=True)


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
