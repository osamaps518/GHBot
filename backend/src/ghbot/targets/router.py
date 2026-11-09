from fastapi import APIRouter

from ghbot.profiles import SavedProfile
from ghbot.targets.application import Targets, calculate_targets

router = APIRouter(prefix="/me/targets")


@router.get("")
async def get_targets(profile: SavedProfile) -> Targets:
    return calculate_targets(profile)
