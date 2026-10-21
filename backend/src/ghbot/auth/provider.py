from datetime import UTC, datetime, timedelta
from typing import Protocol, cast

import jwt


class InvalidToken(ValueError):
    """The provider could not verify the token."""


class AuthProvider(Protocol):
    def verify_token(self, token: str) -> str:
        """Return the provider's user ID, or raise InvalidToken."""
        ...


class DevAuthProvider:
    def __init__(self, secret: str) -> None:
        self._secret = secret

    def issue_token(self, subject: str) -> str:
        now = datetime.now(UTC)
        return jwt.encode(
            {"sub": subject, "iat": now, "exp": now + timedelta(minutes=15)},
            self._secret,
            algorithm="HS256",
        )

    def verify_token(self, token: str) -> str:
        try:
            claims = jwt.decode(
                token,
                self._secret,
                algorithms=["HS256"],
                options={"require": ["sub", "iat", "exp"]},
            )
        except jwt.InvalidTokenError as error:
            raise InvalidToken from error
        return cast(str, claims["sub"])
