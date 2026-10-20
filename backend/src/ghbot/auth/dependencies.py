from typing import Annotated

from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert

from ghbot.auth.models import User
from ghbot.auth.provider import AuthProvider, InvalidToken
from ghbot.database import SessionDependency


async def get_current_user(
    request: Request,
    session: SessionDependency,
    credentials: Annotated[
        HTTPAuthorizationCredentials | None, Depends(HTTPBearer(auto_error=False))
    ],
) -> User:
    unauthorized = HTTPException(
        status_code=401,
        detail="Not authenticated",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is None:
        raise unauthorized

    provider: AuthProvider = request.app.state.auth_provider
    try:
        subject = provider.verify_token(credentials.credentials)
    except InvalidToken:
        raise unauthorized from None

    query = select(User).where(User.auth_subject == subject)
    user = await session.scalar(query)
    if user is None:
        # Concurrent first requests can both miss the lookup. The unique
        # constraint and conflict handling make them share the same user.
        await session.execute(
            insert(User)
            .values(auth_subject=subject)
            .on_conflict_do_nothing(index_elements=[User.auth_subject])
        )
        user = (await session.scalars(query)).one()
        await session.commit()
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]
