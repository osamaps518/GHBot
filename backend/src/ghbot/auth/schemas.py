from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, StringConstraints


class TokenRequest(BaseModel):
    subject: Annotated[
        str, StringConstraints(min_length=1, max_length=255, pattern=r"^[^\x00]*$")
    ]


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: UUID
    created_at: datetime
