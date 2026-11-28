from typing import TypedDict

from pydantic import BaseModel, Field

from ghbot.profiles import ProfileSnapshot
from ghbot.targets.application import Targets, adjusted_custom
from ghbot.targets.models import CustomTargets


class CustomTargetsBody(BaseModel):
    calories: int = Field(strict=True, le=6000)
    protein_g: int = Field(strict=True, ge=0, le=500)
    fat_g: int = Field(strict=True, ge=0, le=300)
    carbs_g: int = Field(strict=True, ge=0, le=1000)


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
    recommended: Targets,
    custom: CustomTargets | None = None,
    profile: ProfileSnapshot | None = None,
) -> TargetsResponse:
    effective = adjusted_custom(profile, custom) if profile and custom else None
    floor_applied = (
        custom is not None
        and effective is not None
        and effective["calories"] != custom.calories
    )
    return {
        "calories": effective["calories"] if effective else recommended["calories"],
        "protein_g": effective["protein_g"] if effective else recommended["protein_g"],
        "fat_g": effective["fat_g"] if effective else recommended["fat_g"],
        "carbs_g": effective["carbs_g"] if effective else recommended["carbs_g"],
        "maintenance_calories": recommended["maintenance_calories"],
        "at_minimum": recommended["at_minimum"] if custom is None else floor_applied,
        "above_tested_age": recommended["above_tested_age"],
        "goal": recommended["goal"],
        "goal_adjustment_percent": recommended["goal_adjustment_percent"],
        "custom": custom is not None,
        "macros_adjusted": floor_applied,
        "recommended": {
            "calories": recommended["calories"],
            "protein_g": recommended["protein_g"],
            "fat_g": recommended["fat_g"],
            "carbs_g": recommended["carbs_g"],
        },
    }
