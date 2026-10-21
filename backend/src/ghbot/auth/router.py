from typing import Annotated
from uuid import UUID

from fastapi import APIRouter
from pydantic import BaseModel, StringConstraints

from ghbot.auth.dependencies import CurrentUser
from ghbot.auth.provider import DevAuthProvider


class TokenRequest(BaseModel):
    subject: Annotated[
        str, StringConstraints(min_length=1, max_length=255, pattern=r"^[^\x00]*$")
    ]


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: UUID


router = APIRouter()


@router.get("/me")
async def me(user: CurrentUser) -> UserResponse:
    return UserResponse(id=user.id)


def create_dev_router(provider: DevAuthProvider) -> APIRouter:
    dev_router = APIRouter(prefix="/dev")

    @dev_router.post("/token")
    async def token(body: TokenRequest) -> TokenResponse:
        return TokenResponse(access_token=provider.issue_token(body.subject))

    return dev_router
