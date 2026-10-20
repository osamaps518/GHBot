from uuid import UUID

from fastapi import APIRouter
from pydantic import BaseModel

from ghbot.auth.dependencies import CurrentUser
from ghbot.auth.provider import DevAuthProvider


class TokenRequest(BaseModel):
    subject: str


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
    router = APIRouter(prefix="/dev")

    @router.post("/token")
    async def token(body: TokenRequest) -> TokenResponse:
        return TokenResponse(access_token=provider.issue_token(body.subject))

    return router
