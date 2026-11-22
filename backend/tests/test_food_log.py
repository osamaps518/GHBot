from uuid import uuid7

import pytest
from sqlalchemy import create_engine, text

from ghbot.config import Settings


@pytest.fixture
def food(engine):
    food_id = uuid7()
    with engine.begin() as connection:
        connection.execute(
            text("""INSERT INTO foods (id, name_ar, source, source_id, calories,
                     protein, carbs, fat) VALUES (:id, 'أرز', 'regional', :source,
                     130, 2.7, 28.2, 0.3)"""),
            {"id": food_id, "source": str(food_id)},
        )
    yield str(food_id)
    with engine.begin() as connection:
        connection.execute(
            text("DELETE FROM food_log_entries WHERE food_id = :id"), {"id": food_id}
        )
        connection.execute(text("DELETE FROM foods WHERE id = :id"), {"id": food_id})


@pytest.fixture
def engine():
    engine = create_engine(Settings().database_url.get_secret_value())
    yield engine
    engine.dispose()


def entry(food):
    return {
        "revision": 1,
        "food_id": food,
        "meal": "lunch",
        "meal_name": None,
        "diary_day": "2026-11-22",
        "grams": "150.0",
        "logged_at": "2026-11-22T12:00:00+00:00",
        "per_100g": {
            "calories": "130.0",
            "protein": "2.7",
            "carbs": "28.2",
            "fat": "0.3",
        },
        "totals": {
            "calories": "195.0",
            "protein": "4.1",
            "carbs": "42.3",
            "fat": "0.5",
        },
    }


def test_put_creates_entry_and_repeat_returns_same_row(client, auth_headers, food):
    headers = auth_headers()
    item_id = str(uuid7())
    body = entry(food)

    first = client.put(f"/me/food-log/entries/{item_id}", headers=headers, json=body)
    repeated = client.put(f"/me/food-log/entries/{item_id}", headers=headers, json=body)

    assert first.status_code == 201
    assert repeated.status_code == 200
    assert repeated.json() == first.json()
    assert first.json() == {
        "id": item_id,
        "deleted": False,
        **body,
        "logged_at": "2026-11-22T12:00:00Z",
    }
