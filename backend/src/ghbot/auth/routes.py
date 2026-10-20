from fastapi import APIRouter
from pydantic import BaseModel

from ghbot.auth.provider import DevAuthProvider


class TokenRequest(BaseModel):
    subject: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


def create_dev_router(provider: DevAuthProvider) -> APIRouter:
    router = APIRouter(prefix="/dev")

    @router.post("/token")
    async def token(body: TokenRequest) -> TokenResponse:
        return TokenResponse(access_token=provider.issue_token(body.subject))

    return router
