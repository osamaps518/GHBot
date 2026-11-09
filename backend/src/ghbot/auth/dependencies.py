from typing import Annotated

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from ghbot.auth.application import find_or_create_user
from ghbot.auth.exceptions import InvalidToken
from ghbot.auth.models import User
from ghbot.auth.provider import AuthProvider
from ghbot.database import SessionDependency

bearer = HTTPBearer()


async def get_current_user(
    request: Request,
    session: SessionDependency,
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer)],
) -> User:
    provider: AuthProvider = request.app.state.auth_provider
    try:
        subject = provider.verify_token(credentials.credentials)
    except InvalidToken:
        raise bearer.make_not_authenticated_error() from None

    return await find_or_create_user(session, subject)


CurrentUser = Annotated[User, Depends(get_current_user)]
