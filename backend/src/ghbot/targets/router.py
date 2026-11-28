from fastapi import APIRouter

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.profiles import SavedProfile
from ghbot.targets.application import Targets, calculate_targets
from ghbot.targets.schemas import TargetsResponse, response_for

router = APIRouter(prefix="/me/targets")


@router.get("")
async def get_targets(
    profile: SavedProfile, user: CurrentUser, session: SessionDependency
) -> TargetsResponse:
    recommended: Targets = calculate_targets(profile)
    return response_for(recommended)
