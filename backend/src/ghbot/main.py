from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from ghbot.config import Settings
from ghbot.database import Database


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[dict[str, Database]]:
        database = Database(settings)
        try:
            yield {"database": database}
        finally:
            await database.close()

    app = FastAPI(title="GHBot", lifespan=lifespan)

    @app.get("/health", tags=["health"])
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    return app
