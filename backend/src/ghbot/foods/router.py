from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query
from pydantic import BaseModel

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.foods.application import search_foods


class FoodResponse(BaseModel):
    id: UUID
    name_ar: str | None
    name_en: str | None
    calories: float
    protein: float
    carbs: float
    fat: float


router = APIRouter(prefix="/foods")


@router.get("", response_model=list[FoodResponse])
async def get_foods(
    q: Annotated[str, Query(min_length=1, max_length=100, pattern=r"^[^\x00]*$")],
    user: CurrentUser,
    session: SessionDependency,
) -> list[dict[str, object]]:
    return await search_foods(session, user.id, q)
