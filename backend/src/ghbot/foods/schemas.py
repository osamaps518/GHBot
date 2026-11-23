from uuid import UUID

from pydantic import BaseModel


class FoodResponse(BaseModel):
    id: UUID
    name_ar: str | None
    name_en: str | None
    calories: float
    protein: float
    carbs: float
    fat: float
