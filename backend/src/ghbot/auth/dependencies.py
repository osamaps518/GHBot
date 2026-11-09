from typing import Annotated

from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from ghbot.auth.application import find_or_create_user
from ghbot.auth.exceptions import InvalidToken
from ghbot.auth.models import User
from ghbot.auth.provider import AuthProvider
from ghbot.database import SessionDependency


async def get_current_user(
    request: Request,
    session: SessionDependency,
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(HTTPBearer())],
) -> User:
    unauthorized = HTTPException(
        status_code=401,
        detail="Not authenticated",
        headers={"WWW-Authenticate": "Bearer"},
    )
    provider: AuthProvider = request.app.state.auth_provider
    try:
        subject = provider.verify_token(credentials.credentials)
    except InvalidToken:
        raise unauthorized from None

    return await find_or_create_user(session, subject)


CurrentUser = Annotated[User, Depends(get_current_user)]
