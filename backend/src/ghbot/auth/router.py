from fastapi import APIRouter

from ghbot.auth.dependencies import CurrentUser
from ghbot.auth.provider import DevAuthProvider
from ghbot.auth.schemas import TokenRequest, TokenResponse, UserResponse

router = APIRouter()


@router.get("/me")
async def me(user: CurrentUser) -> UserResponse:
    return UserResponse(id=user.id, created_at=user.created_at)


def create_dev_router(provider: DevAuthProvider) -> APIRouter:
    dev_router = APIRouter(prefix="/dev")

    @dev_router.post("/token")
    async def token(body: TokenRequest) -> TokenResponse:
        return TokenResponse(access_token=provider.issue_token(body.subject))

    return dev_router
