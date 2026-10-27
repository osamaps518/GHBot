from fastapi import APIRouter, HTTPException

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.profiles import Profile

router = APIRouter(prefix="/me/targets")


@router.get("")
async def get_targets(user: CurrentUser, session: SessionDependency) -> None:
    profile = await session.get(Profile, user.id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
