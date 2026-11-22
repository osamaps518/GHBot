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
from ghbot.food_log import router as food_log_router
from ghbot.foods import router as foods_router
from ghbot.profiles import router as profiles_router
from ghbot.targets import router as targets_router


def create_app() -> FastAPI:
    settings = Settings()
    if settings.environment != "development":
        raise ValueError("Dev sign-in is only available in development")

    @asynccontextmanager
    async def lifespan(
        app: FastAPI,
    ) -> AsyncIterator[dict[str, async_sessionmaker[AsyncSession]]]:
        """Open the database engine for the app's lifetime.

        The engine connects lazily, so the app starts even if Postgres is down.
        Sessions keep their fields after commit (expire_on_commit=False);
        otherwise reading a field would trigger a hidden query, which async
        SQLAlchemy can't do.
        """
        engine = create_async_engine(
            settings.database_url.get_secret_value(), hide_parameters=True
        )
        try:
            yield {"sessions": async_sessionmaker(engine, expire_on_commit=False)}
        finally:
            await engine.dispose()

    app = FastAPI(title="GHBot", lifespan=lifespan)
    provider = DevAuthProvider(settings.dev_jwt_secret.get_secret_value())
    app.state.auth_provider = provider
    app.include_router(router)
    app.include_router(profiles_router)
    app.include_router(targets_router)
    app.include_router(foods_router)
    app.include_router(food_log_router)
    app.include_router(create_dev_router(provider))

    @app.exception_handler(RequestValidationError)
    async def validation_error_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        """Return FastAPI's default 422 body, safe for every value it echoes.

        The JSON parser accepts values the response can't hold: NaN and
        Infinity (json.dumps gives the text that was sent), and lone surrogates
        like \\ud800, which UTF-8 can't encode (backslashreplace sends them back
        as text).
        """
        errors = jsonable_encoder(
            exc.errors(),
            custom_encoder={
                float: lambda x: x if math.isfinite(x) else json.dumps(x),
                str: lambda x: x.encode("utf-8", "backslashreplace").decode("utf-8"),
            },
        )
        return JSONResponse(status_code=422, content={"detail": errors})

    @app.get("/health")
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    return app
