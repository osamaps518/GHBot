import json
import math
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from ghbot.auth import DevAuthProvider, create_dev_router, router
from ghbot.config import Settings
from ghbot.profiles import router as profiles_router


def create_app() -> FastAPI:
    settings = Settings()
    if settings.environment != "development":
        raise ValueError("Dev sign-in is only available in development")

    @asynccontextmanager
    async def lifespan(
        app: FastAPI,
    ) -> AsyncIterator[dict[str, async_sessionmaker[AsyncSession]]]:
        # The engine connects lazily, so the app starts even if Postgres is down.
        engine = create_async_engine(settings.database_url.get_secret_value())
        # Without expire_on_commit=False, reading a field after commit would
        # trigger a hidden query, which async SQLAlchemy can't do.
        yield {"sessions": async_sessionmaker(engine, expire_on_commit=False)}
        await engine.dispose()

    app = FastAPI(title="GHBot", lifespan=lifespan)
    provider = DevAuthProvider(settings.dev_jwt_secret.get_secret_value())
    app.state.auth_provider = provider
    app.include_router(router)
    app.include_router(profiles_router)
    app.include_router(create_dev_router(provider))

    @app.exception_handler(RequestValidationError)
    async def validation_error_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        # Same as FastAPI's default, except NaN and Infinity, which the JSON
        # parser accepts but JSON can't hold. json.dumps gives the text sent.
        errors = jsonable_encoder(
            exc.errors(),
            custom_encoder={float: lambda x: x if math.isfinite(x) else json.dumps(x)},
        )
        return JSONResponse(status_code=422, content={"detail": errors})

    @app.get("/health")
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    return app
