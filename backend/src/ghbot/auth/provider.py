from datetime import UTC, datetime, timedelta

import jwt


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
