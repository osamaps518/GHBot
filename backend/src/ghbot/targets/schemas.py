from typing import TypedDict

from pydantic import BaseModel, Field

from ghbot.profiles import ProfileSnapshot
from ghbot.targets.application import Targets, adjusted_custom, calculate_targets
from ghbot.targets.models import CustomTargets


class CustomTargetsBody(BaseModel):
    calories: int = Field(le=6000)
    protein_g: int = Field(ge=0, le=500)
    fat_g: int = Field(ge=0, le=300)
    carbs_g: int = Field(ge=0, le=1000)


class MacroValues(TypedDict):
    calories: int
    protein_g: int
    fat_g: int
    carbs_g: int


class TargetsResponse(Targets):
    custom: bool
    macros_adjusted: bool
    recommended: MacroValues


def response_for(
    profile: ProfileSnapshot, custom: CustomTargets | None = None
) -> TargetsResponse:
    recommended = calculate_targets(profile)
    effective = adjusted_custom(profile, custom) if custom else None
    in_effect = effective or recommended
    raised = custom is not None and in_effect["calories"] != custom.calories
    macros_adjusted = custom is not None and (
        in_effect["protein_g"],
        in_effect["fat_g"],
        in_effect["carbs_g"],
    ) != (custom.protein_g, custom.fat_g, custom.carbs_g)
    return {
        "calories": in_effect["calories"],
        "protein_g": in_effect["protein_g"],
        "fat_g": in_effect["fat_g"],
        "carbs_g": in_effect["carbs_g"],
        "maintenance_calories": recommended["maintenance_calories"],
        "at_minimum": recommended["at_minimum"] if custom is None else raised,
        "above_tested_age": recommended["above_tested_age"],
        "goal": recommended["goal"],
        "goal_adjustment_percent": recommended["goal_adjustment_percent"],
        "custom": custom is not None,
        "macros_adjusted": macros_adjusted,
        "recommended": {
            "calories": recommended["calories"],
            "protein_g": recommended["protein_g"],
            "fat_g": recommended["fat_g"],
            "carbs_g": recommended["carbs_g"],
        },
    }
