from datetime import UTC, date, datetime
from typing import Annotated

from fastapi import Depends, HTTPException

from ghbot.auth import CurrentUser
from ghbot.database import SessionDependency
from ghbot.profiles.application import ProfileSnapshot, read_profile
from ghbot.profiles.exceptions import ProfileNotFound


def utc_today() -> date:
    return datetime.now(UTC).date()


async def get_saved_profile(
    user: CurrentUser,
    session: SessionDependency,
    today: Annotated[date, Depends(utc_today)],
) -> ProfileSnapshot:
    try:
        return await read_profile(session, user.id, today)
    except ProfileNotFound:
        raise HTTPException(status_code=404, detail="Profile not found") from None


SavedProfile = Annotated[ProfileSnapshot, Depends(get_saved_profile)]
