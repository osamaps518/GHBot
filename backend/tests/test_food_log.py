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


def test_newer_revision_replaces_entry_and_lower_revision_returns_stored_one(
    client, auth_headers, food
):
    headers = auth_headers()
    url = f"/me/food-log/entries/{uuid7()}"
    first = entry(food)
    assert client.put(url, headers=headers, json=first).status_code == 201
    newer = {**first, "revision": 2, "meal": "dinner"}
    changed = client.put(url, headers=headers, json=newer)
    stale = client.put(url, headers=headers, json=first)

    assert changed.status_code == 200
    assert changed.json()["revision"] == 2
    assert changed.json()["meal"] == "dinner"
    assert stale.status_code == 200
    assert stale.json() == changed.json()


def test_other_trainee_cannot_replace_or_delete_entry(client, auth_headers, food):
    owner = auth_headers()
    other = auth_headers()
    url = f"/me/food-log/entries/{uuid7()}"
    original = client.put(url, headers=owner, json=entry(food)).json()

    replaced = client.put(url, headers=other, json={**entry(food), "revision": 2})
    deleted = client.delete(url, headers=other)

    assert replaced.status_code == 409
    assert deleted.status_code == 409
    assert client.put(url, headers=owner, json=entry(food)).json() == original


def test_delete_is_final_and_repeating_it_returns_stored_row(
    client, auth_headers, food
):
    headers = auth_headers()
    url = f"/me/food-log/entries/{uuid7()}"
    assert client.put(url, headers=headers, json=entry(food)).status_code == 201

    deleted = client.delete(url, headers=headers)
    repeated = client.delete(url, headers=headers)
    late = client.put(url, headers=headers, json={**entry(food), "revision": 3})

    assert deleted.status_code == 200
    assert deleted.json()["deleted"] is True
    assert deleted.json()["revision"] == 1
    assert repeated.json() == deleted.json()
    assert late.status_code == 200
    assert late.json() == deleted.json()


def test_delete_before_put_records_tombstone(client, auth_headers, food):
    headers = auth_headers()
    url = f"/me/food-log/entries/{uuid7()}"

    deleted = client.delete(url, headers=headers)
    late = client.put(url, headers=headers, json=entry(food))

    assert deleted.status_code == 200
    assert deleted.json() == {
        "id": url.rsplit("/", 1)[1], "revision": 0, "deleted": True,
        "food_id": None, "meal": None, "meal_name": None, "diary_day": None,
        "grams": None, "logged_at": None, "per_100g": None, "totals": None,
    }
    assert late.status_code == 200
    assert late.json() == deleted.json()
