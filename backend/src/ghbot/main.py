from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from ghbot.auth.provider import DevAuthProvider
from ghbot.auth.router import create_dev_router, router
from ghbot.config import Settings


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
    app.include_router(create_dev_router(provider))

    @app.get("/health")
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    return app
