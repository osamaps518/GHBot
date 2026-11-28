from typing import TypedDict

from ghbot.targets.application import Targets


class MacroValues(TypedDict):
    calories: int
    protein_g: int
    fat_g: int
    carbs_g: int


class TargetsResponse(Targets):
    custom: bool
    macros_adjusted: bool
    recommended: MacroValues


def response_for(recommended: Targets) -> TargetsResponse:
    return {
        **recommended,
        "custom": False,
        "macros_adjusted": False,
        "recommended": {
            "calories": recommended["calories"],
            "protein_g": recommended["protein_g"],
            "fat_g": recommended["fat_g"],
            "carbs_g": recommended["carbs_g"],
        },
    }
