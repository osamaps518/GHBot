"""Calculate recommended targets and manage saved custom targets.

The agreed calculation writes all Decimal constants as strings, so FURB157 is
off for this file.

Mifflin-St Jeor was tested on adults aged 19 to 78 (OLDEST_TESTED_AGE). Above
that, the app warns that the estimate may be less accurate.
"""

# ruff: noqa: FURB157

from datetime import date
from decimal import ROUND_HALF_UP, Decimal
from typing import TypedDict
from uuid import UUID

from sqlalchemy import delete, func
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from ghbot.profiles import Goal, ProfileSnapshot, Sex
from ghbot.targets.exceptions import BelowMinimum, MacrosMismatch
from ghbot.targets.models import CustomTargets, TargetHistory


class Targets(TypedDict):
    calories: int
    protein_g: int
    fat_g: int
    carbs_g: int
    maintenance_calories: int
    at_minimum: bool
    above_tested_age: bool
    goal: Goal
    goal_adjustment_percent: int


OLDEST_TESTED_AGE = 78

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


def calorie_minimum(sex: Sex) -> int:
    """Return the agreed daily calorie floor for this profile."""
    return 1500 if sex == "male" else 1200


def adjusted_custom(profile: ProfileSnapshot, custom: CustomTargets) -> dict[str, int]:
    """Raise an older custom target to the current minimum and fill its macros."""
    minimum = calorie_minimum(profile.sex)
    if custom.calories >= minimum:
        return {
            "calories": custom.calories,
            "protein_g": custom.protein_g,
            "fat_g": custom.fat_g,
            "carbs_g": custom.carbs_g,
        }
    weight = Decimal(str(profile.weight_kg))
    height_m = Decimal(str(profile.height_cm)) / Decimal("100")
    if weight / height_m**2 >= Decimal("30"):
        weight = Decimal("25") * height_m**2
    protein = max(custom.protein_g, _whole(Decimal("1.6") * weight))
    fat = max(custom.fat_g, _whole(Decimal(minimum) * Decimal("0.2") / 9))
    available = minimum - 4 * protein - 9 * fat
    carbs = min(custom.carbs_g, max(0, _whole(Decimal(available) / 4)))
    carb_cap = _whole(Decimal(minimum) * Decimal("0.65") / 4)
    carbs = max(
        carbs, min(carb_cap, _whole(Decimal(minimum - 4 * protein - 9 * fat) / 4))
    )
    remaining = minimum - 4 * protein - 9 * fat - 4 * carbs
    protein += min(
        max(0, _whole(Decimal("2.2") * weight) - protein), max(0, remaining // 4)
    )
    remaining = minimum - 4 * protein - 9 * fat - 4 * carbs
    fat += min(
        max(0, _whole(Decimal(minimum) * Decimal("0.35") / 9) - fat),
        max(0, remaining // 9),
    )
    return {"calories": minimum, "protein_g": protein, "fat_g": fat, "carbs_g": carbs}


async def read_custom(session: AsyncSession, user_id: UUID) -> CustomTargets | None:
    return await session.get(CustomTargets, user_id)


async def save_custom(
    session: AsyncSession,
    user_id: UUID,
    profile: ProfileSnapshot,
    values: dict[str, int],
    today: date,
) -> CustomTargets:
    """Save values and their history together after checking the profile floor."""
    if values["calories"] < calorie_minimum(profile.sex):
        raise BelowMinimum
    energy = 4 * (values["protein_g"] + values["carbs_g"]) + 9 * values["fat_g"]
    if abs(energy - values["calories"]) >= 100:
        raise MacrosMismatch
    statement = insert(CustomTargets).values(user_id=user_id, **values)
    row = (
        await session.scalars(
            statement.on_conflict_do_update(
                index_elements=[CustomTargets.user_id],
                set_={**values, "updated_at": func.clock_timestamp()},
            ).returning(CustomTargets)
        )
    ).one()
    recommended = calculate_targets(profile)
    session.add(
        TargetHistory(
            user_id=user_id,
            kind="manual_edit",
            date=today,
            recommended_calories=recommended["calories"],
            recommended_protein_g=recommended["protein_g"],
            recommended_fat_g=recommended["fat_g"],
            recommended_carbs_g=recommended["carbs_g"],
            custom_calories=values["calories"],
            custom_protein_g=values["protein_g"],
            custom_fat_g=values["fat_g"],
            custom_carbs_g=values["carbs_g"],
        )
    )
    await session.commit()
    return row


async def reset_custom(
    session: AsyncSession, user_id: UUID, profile: ProfileSnapshot, today: date
) -> None:
    """Remove an existing custom row and record its former values once."""
    previous = (
        await session.scalars(
            delete(CustomTargets)
            .where(CustomTargets.user_id == user_id)
            .returning(CustomTargets)
        )
    ).one_or_none()
    if previous is None:
        return
    recommended = calculate_targets(profile)
    session.add(
        TargetHistory(
            user_id=user_id,
            kind="reset",
            date=today,
            recommended_calories=recommended["calories"],
            recommended_protein_g=recommended["protein_g"],
            recommended_fat_g=recommended["fat_g"],
            recommended_carbs_g=recommended["carbs_g"],
            custom_calories=previous.calories,
            custom_protein_g=previous.protein_g,
            custom_fat_g=previous.fat_g,
            custom_carbs_g=previous.carbs_g,
        )
    )
    await session.commit()


def _whole(value: Decimal) -> int:
    return int(value.quantize(Decimal("1"), rounding=ROUND_HALF_UP))


def _nearest_ten(value: Decimal) -> int:
    return _whole(value / Decimal("10")) * 10


def calculate_targets(
    profile: ProfileSnapshot,
) -> Targets:
    weight = Decimal(str(profile.weight_kg))
    height = Decimal(str(profile.height_cm))
    bmr = (
        Decimal("10") * weight
        + Decimal("6.25") * height
        - Decimal("5") * profile.age
        + (Decimal("5") if profile.sex == "male" else Decimal("-161"))
    )
    maintenance = bmr * ACTIVITY_FACTORS[profile.activity_level]
    proposed = maintenance * GOAL_FACTORS[profile.goal]
    minimum = Decimal(calorie_minimum(profile.sex))
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
        "above_tested_age": profile.age > OLDEST_TESTED_AGE,
        "goal": profile.goal,
        "goal_adjustment_percent": _whole(
            (GOAL_FACTORS[profile.goal] - Decimal("1")) * Decimal("100")
        ),
    }
