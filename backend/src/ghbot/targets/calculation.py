"""Calculate daily calories and macros from an onboarding profile."""

# The agreed calculation writes all Decimal constants as strings.
# ruff: noqa: FURB157

from decimal import ROUND_HALF_UP, Decimal
from typing import TypedDict


class Targets(TypedDict):
    calories: int
    protein_g: int
    fat_g: int
    carbs_g: int
    maintenance_calories: int
    at_minimum: bool


ACTIVITY_FACTORS = {
    "sedentary": Decimal("1.2"),
    "lightly_active": Decimal("1.375"),
    "moderately_active": Decimal("1.55"),
    "very_active": Decimal("1.725"),
    "extremely_active": Decimal("1.9"),
}
GOAL_FACTORS = {
    "lose": Decimal("0.8"),
    "maintain": Decimal("1.0"),
    "gain": Decimal("1.1"),
}


def _whole(value: Decimal) -> int:
    return int(value.quantize(Decimal("1"), rounding=ROUND_HALF_UP))


def _nearest_ten(value: Decimal) -> int:
    return _whole(value / Decimal("10")) * 10


def calculate_targets(
    sex: str,
    age: int,
    weight_kg: float,
    height_cm: float,
    activity_level: str,
    goal: str,
) -> Targets:
    weight = Decimal(str(weight_kg))
    height = Decimal(str(height_cm))
    bmr = (
        Decimal("10") * weight
        + Decimal("6.25") * height
        - Decimal("5") * age
        + (Decimal("5") if sex == "male" else Decimal("-161"))
    )
    maintenance = bmr * ACTIVITY_FACTORS[activity_level]
    proposed = maintenance * GOAL_FACTORS[goal]
    minimum = Decimal("1500") if sex == "male" else Decimal("1200")
    at_minimum = proposed < minimum
    calories = _nearest_ten(max(proposed, minimum))

    height_m = height / Decimal("100")
    protein_weight = weight
    if weight / height_m**2 >= Decimal("30"):
        protein_weight = Decimal("25") * height_m**2
    protein_g = _whole(Decimal("2.2") * protein_weight)
    fat_g = _whole(Decimal(calories) * Decimal("0.2") / Decimal("9"))
    carbs = Decimal(calories - protein_g * 4 - fat_g * 9) / Decimal("4")
    if carbs < 0:
        raise ValueError("Calculated carbohydrates cannot be negative")

    return {
        "calories": calories,
        "protein_g": protein_g,
        "fat_g": fat_g,
        "carbs_g": _whole(carbs),
        "maintenance_calories": _nearest_ten(maintenance),
        "at_minimum": at_minimum,
    }
