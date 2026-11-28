from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.exceptions import RequestValidationError

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.profiles import SavedProfile, utc_today
from ghbot.targets.application import (
    Targets,
    calculate_targets,
    calorie_minimum,
    read_custom,
    reset_custom,
    save_custom,
)
from ghbot.targets.exceptions import BelowMinimum, MacrosMismatch
from ghbot.targets.schemas import CustomTargetsBody, TargetsResponse, response_for

router = APIRouter(prefix="/me/targets")


@router.get("")
async def get_targets(
    profile: SavedProfile, user: CurrentUser, session: SessionDependency
) -> TargetsResponse:
    recommended: Targets = calculate_targets(profile)
    custom = await read_custom(session, user.id)
    return response_for(recommended, custom, profile)


@router.put("/custom")
async def put_custom_targets(
    body: CustomTargetsBody,
    profile: SavedProfile,
    user: CurrentUser,
    session: SessionDependency,
    today: Annotated[date, Depends(utc_today)],
) -> TargetsResponse:
    try:
        custom = await save_custom(session, user.id, profile, body.model_dump(), today)
    except BelowMinimum:
        raise RequestValidationError(
            [
                {
                    "type": "below_minimum",
                    "loc": ("body", "calories"),
                    "msg": "Calories are below the minimum",
                    "input": body.calories,
                    "ctx": {"minimum": calorie_minimum(profile.sex)},
                }
            ]
        ) from None
    except MacrosMismatch:
        raise RequestValidationError(
            [
                {
                    "type": "macros_mismatch",
                    "loc": ("body",),
                    "msg": "Macro calories differ by at least 100",
                    "input": body.model_dump(),
                }
            ]
        ) from None
    return response_for(calculate_targets(profile), custom, profile)


@router.delete("/custom")
async def delete_custom_targets(
    profile: SavedProfile,
    user: CurrentUser,
    session: SessionDependency,
    today: Annotated[date, Depends(utc_today)],
) -> TargetsResponse:
    await reset_custom(session, user.id, profile, today)
    return response_for(calculate_targets(profile))
