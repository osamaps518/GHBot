import pytest


@pytest.mark.anyio
async def test_health_reports_a_running_process(client):
    response = await client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


@pytest.mark.anyio
async def test_public_docs_and_openapi_describe_health(client):
    docs = await client.get("/docs")
    schema = await client.get("/openapi.json")

    assert docs.status_code == 200
    assert docs.headers["content-type"].startswith("text/html")
    assert schema.status_code == 200
    assert "get" in schema.json()["paths"]["/health"]
