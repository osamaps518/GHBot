from typing import Annotated

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from ghbot.auth.application import SignedInUser, find_or_create_user
from ghbot.auth.exceptions import InvalidToken
from ghbot.auth.provider import AuthProvider
from ghbot.database import SessionDependency

bearer = HTTPBearer()


async def get_current_user(
    request: Request,
    session: SessionDependency,
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer)],
) -> SignedInUser:
    """Return the user the bearer token names, or answer 401.

    The app's `AuthProvider` verifies the token and gives its subject, which is
    mapped to our users table, creating the row on first use.
    """
    provider: AuthProvider = request.app.state.auth_provider
    try:
        subject = provider.verify_token(credentials.credentials)
    except InvalidToken:
        raise bearer.make_not_authenticated_error() from None

    return await find_or_create_user(session, subject)


CurrentUser = Annotated[SignedInUser, Depends(get_current_user)]
