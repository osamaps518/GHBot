from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, Response

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.foods.application import FoodOfAnotherUser, put_own_food, search_foods
from ghbot.foods.schemas import FoodResponse, OwnFoodBody

router = APIRouter()


@router.get("/foods", response_model=list[FoodResponse])
async def get_foods(
    q: Annotated[str, Query(min_length=1, max_length=100, pattern=r"^[^\x00]*$")],
    user: CurrentUser,
    session: SessionDependency,
) -> list[dict[str, object]]:
    return await search_foods(session, user.id, q)


@router.put("/me/foods/{id}", response_model=FoodResponse)
async def put_food(
    id: UUID,
    body: OwnFoodBody,
    user: CurrentUser,
    session: SessionDependency,
    response: Response,
) -> dict[str, object]:
    try:
        stored, created = await put_own_food(session, user.id, id, body.model_dump())
    except FoodOfAnotherUser:
        raise HTTPException(status_code=409, detail="Food ID is not owned") from None
    if created:
        response.status_code = 201
    return stored
