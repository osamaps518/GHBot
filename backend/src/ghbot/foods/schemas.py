from decimal import Decimal
from typing import Annotated, Self
from uuid import UUID

from pydantic import (
    BaseModel,
    Field,
    PlainSerializer,
    StringConstraints,
    model_validator,
)

FoodName = Annotated[
    str, StringConstraints(min_length=1, max_length=80, pattern=r"^[^\x00]*$")
]
Calories = Annotated[
    Decimal,
    Field(ge=0, le=900, decimal_places=1),
    PlainSerializer(float, when_used="json"),
]
Macro = Annotated[
    Decimal,
    Field(ge=0, le=100, decimal_places=1),
    PlainSerializer(float, when_used="json"),
]


class OwnFoodBody(BaseModel):
    revision: int = Field(ge=1, le=2_147_483_647)
    name_ar: FoodName | None = None
    name_en: FoodName | None = None
    calories: Calories
    protein: Macro
    carbs: Macro
    fat: Macro
    barcode: Annotated[str, StringConstraints(pattern=r"^[0-9]{8,14}$")] | None = None

    @model_validator(mode="after")
    def check_food(self) -> Self:
        """Require a visible name and at most 100 g of combined macros."""
        if not any(
            name is not None and name.strip() for name in (self.name_ar, self.name_en)
        ):
            raise ValueError("At least one nonblank name is required")
        if any(
            name is not None and not name.strip()
            for name in (self.name_ar, self.name_en)
        ):
            raise ValueError("Given names cannot contain only spaces")
        if self.protein + self.carbs + self.fat > 100:
            raise ValueError("Combined macros cannot exceed 100 g")
        return self


class FoodResponse(BaseModel):
    id: UUID
    name_ar: str | None
    name_en: str | None
    calories: float
    protein: float
    carbs: float
    fat: float
    barcode: str | None
    own: bool
    revision: int
