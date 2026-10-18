from fastapi import FastAPI


def create_app() -> FastAPI:
    app = FastAPI(title="GHBot")

    @app.get("/health", tags=["health"])
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    return app
