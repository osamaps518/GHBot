from datetime import date
from decimal import ROUND_HALF_UP, Decimal
from typing import Annotated, Literal, Self
from uuid import UUID

from fastapi import APIRouter, Response
from pydantic import AwareDatetime, BaseModel, Field, model_validator

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.food_log.application import delete_entry, put_entry
from ghbot.food_log.models import FoodLogEntry

Grams = Annotated[Decimal, Field(gt=0, le=5000, decimal_places=1)]
Calories = Annotated[Decimal, Field(ge=0, le=900, decimal_places=1)]
Macro = Annotated[Decimal, Field(ge=0, le=100, decimal_places=1)]
Total = Annotated[Decimal, Field(ge=0, decimal_places=1)]


class Nutrients(BaseModel):
    calories: Calories
    protein: Macro
    carbs: Macro
    fat: Macro


class Totals(BaseModel):
    calories: Total
    protein: Total
    carbs: Total
    fat: Total


class EntryBody(BaseModel):
    revision: int = Field(ge=1)
    food_id: UUID
    meal: Literal["breakfast", "lunch", "dinner", "extra"]
    meal_name: str | None
    diary_day: date
    grams: Grams
    logged_at: AwareDatetime
    per_100g: Nutrients
    totals: Totals

    @model_validator(mode="after")
    def check_entry(self) -> Self:
        if self.meal == "extra":
            if (
                self.meal_name is None
                or not 1 <= len(self.meal_name) <= 40
                or not self.meal_name.strip()
            ):
                raise ValueError("Extra meals need a name of 1 to 40 characters")
        elif self.meal_name is not None:
            raise ValueError("Only extra meals may have a name")
        for name in ("calories", "protein", "carbs", "fat"):
            value = getattr(self.per_100g, name)
            expected = (value * self.grams / 100).quantize(
                Decimal("0.1"), rounding=ROUND_HALF_UP
            )
            if getattr(self.totals, name) != expected:
                raise ValueError(f"Incorrect {name} total")
        return self


class EntryResponse(BaseModel):
    id: UUID
    revision: int
    deleted: bool
    food_id: UUID | None
    meal: str | None
    meal_name: str | None
    diary_day: date | None
    grams: Decimal | None
    logged_at: AwareDatetime | None
    per_100g: dict[str, Decimal | None] | None
    totals: dict[str, Decimal | None] | None


def response_for(row: FoodLogEntry) -> EntryResponse:
    """Present a stored row with the contract's nested nutrient groups."""
    per_100g = {
        name: getattr(row, f"{name}_per_100g")
        for name in ("calories", "protein", "carbs", "fat")
    }
    totals = {
        name: getattr(row, name) for name in ("calories", "protein", "carbs", "fat")
    }
    return EntryResponse(
        id=row.id,
        revision=row.revision,
        deleted=row.deleted,
        food_id=row.food_id,
        meal=row.meal,
        meal_name=row.meal_name,
        diary_day=row.diary_day,
        grams=row.grams,
        logged_at=row.logged_at,
        per_100g=per_100g if row.food_id is not None else None,
        totals=totals if row.food_id is not None else None,
    )


router = APIRouter(prefix="/me/food-log/entries")


@router.put("/{id}")
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
    for name in ("calories", "protein", "carbs", "fat"):
        values[f"{name}_per_100g"] = getattr(body.per_100g, name)
        values[name] = getattr(body.totals, name)
    row, created = await put_entry(session, user.id, id, values)
    response.status_code = 201 if created else 200
    return response_for(row)


@router.delete("/{id}")
async def delete_food_log_entry(
    id: UUID, user: CurrentUser, session: SessionDependency
) -> EntryResponse:
    return response_for(await delete_entry(session, user.id, id))
