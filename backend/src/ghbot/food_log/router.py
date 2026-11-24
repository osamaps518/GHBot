from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, Response
from fastapi.exceptions import RequestValidationError
from pydantic import AwareDatetime

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.food_log.application import delete_entry, pull_entries, pull_marker, put_entry
from ghbot.food_log.exceptions import (
    EntryOfAnotherUser,
    EntryWriteFailed,
    FoodNotVisible,
)
from ghbot.food_log.schemas import (
    NUTRIENTS,
    EntryBody,
    EntryResponse,
    PullResponse,
    response_for,
)
from ghbot.foods import changed_foods

router = APIRouter(prefix="/me/food-log")


@router.get("/changes")
async def get_food_log_changes(
    user: CurrentUser,
    session: SessionDependency,
    since: Annotated[AwareDatetime | None, Query()] = None,
) -> PullResponse:
    marker = await pull_marker(session)
    entries = await pull_entries(session, user.id, since)
    foods = await changed_foods(session, user.id, since)
    return PullResponse(
        entries=[response_for(row) for row in entries],
        foods=foods,
        next_marker=marker,
    )


@router.put("/entries/{id}")
async def put_food_log_entry(
    id: UUID,
    body: EntryBody,
    user: CurrentUser,
    session: SessionDependency,
    response: Response,
) -> EntryResponse:
    values: dict[str, object] = {
        "revision": body.revision,
        "food_id": body.food_id,
        "meal": body.meal,
        "meal_name": body.meal_name,
        "diary_day": body.diary_day,
        "grams": body.grams,
        "logged_at": body.logged_at,
    }
    for name in NUTRIENTS:
        values[f"{name}_per_100g"] = getattr(body.per_100g, name)
        values[name] = getattr(body.totals, name)
    try:
        row, created = await put_entry(session, user.id, id, values)
    except FoodNotVisible:
        raise RequestValidationError(
            [
                {
                    "type": "food_not_visible",
                    "loc": ("body", "food_id"),
                    "msg": "Food is not visible",
                    "input": str(body.food_id),
                }
            ]
        ) from None
    except EntryOfAnotherUser:
        raise HTTPException(
            status_code=409, detail="Entry belongs to another user"
        ) from None
    except EntryWriteFailed:
        raise HTTPException(status_code=500, detail="Food log write failed") from None
    response.status_code = 201 if created else 200
    return response_for(row)


@router.delete("/entries/{id}")
async def delete_food_log_entry(
    id: UUID, user: CurrentUser, session: SessionDependency
) -> EntryResponse:
    try:
        row = await delete_entry(session, user.id, id)
    except EntryOfAnotherUser:
        raise HTTPException(
            status_code=409, detail="Entry belongs to another user"
        ) from None
    except EntryWriteFailed:
        raise HTTPException(status_code=500, detail="Food log write failed") from None
    return response_for(row)
