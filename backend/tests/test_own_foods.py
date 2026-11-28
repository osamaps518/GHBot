from uuid import uuid7

import pytest
from sqlalchemy import create_engine, text

from ghbot.config import Settings


@pytest.fixture
def catalog_food():
    engine = create_engine(Settings().database_url.get_secret_value())
    food_id = uuid7()
    with engine.begin() as connection:
        connection.execute(
            text("""INSERT INTO foods (id, name_ar, source, source_id, calories,
                 protein, carbs, fat) VALUES (:id, 'طعام عام', 'regional', :source_id,
                 100, 1, 2, 3)"""),
            {"id": food_id, "source_id": str(food_id)},
        )
    yield str(food_id)
    with engine.begin() as connection:
        connection.execute(text("DELETE FROM foods WHERE id = :id"), {"id": food_id})
    engine.dispose()


def own_food(**changes):
    return {
        "revision": 1,
        "name_ar": "حمص بيتي",
        "name_en": "Home hummus",
        "calories": 170.0,
        "protein": 8.0,
        "carbs": 15.0,
        "fat": 9.0,
        "barcode": "12345678",
        **changes,
    }


def test_create_replace_and_stale_revision_return_stored_food(client, auth_headers):
    headers = auth_headers()
    food_id = str(uuid7())
    url = f"/me/foods/{food_id}"
    first = client.put(url, headers=headers, json=own_food())
    assert first.status_code == 201
    assert first.json() == {
        "id": food_id,
        "name_ar": "حمص بيتي",
        "name_en": "Home hummus",
        "calories": 170.0,
        "protein": 8.0,
        "carbs": 15.0,
        "fat": 9.0,
        "barcode": "12345678",
        "own": True,
        "revision": 1,
    }
    newer = client.put(
        url, headers=headers, json=own_food(revision=2, name_en="Hummus")
    )
    stale = client.put(url, headers=headers, json=own_food())
    equal = client.put(
        url, headers=headers, json=own_food(revision=2, name_en="Ignored")
    )
    assert newer.status_code == 200
    assert newer.json()["name_en"] == "Hummus"
    assert stale.status_code == 200
    assert stale.json() == newer.json()
    assert equal.status_code == 200
    assert equal.json() == newer.json()


def test_own_food_is_private_in_search_and_pull(client, auth_headers):
    owner, other = auth_headers(), auth_headers()
    food_id = str(uuid7())
    assert (
        client.put(
            f"/me/foods/{food_id}",
            headers=owner,
            json=own_food(
                owner_id=client.get("/me", headers=other).json()["id"],
                source="regional",
            ),
        ).status_code
        == 201
    )

    owner_search = client.get("/foods", headers=owner, params={"q": "حمص بيتي"})
    other_search = client.get("/foods", headers=other, params={"q": "حمص بيتي"})
    owner_pull = client.get("/me/food-log/changes", headers=owner)
    other_pull = client.get("/me/food-log/changes", headers=other)

    assert [row["id"] for row in owner_search.json()] == [food_id]
    assert other_search.json() == []
    assert [row["id"] for row in owner_pull.json()["foods"]] == [food_id]
    assert other_pull.json()["foods"] == []


def test_catalog_and_other_trainees_ids_cannot_be_replaced(
    client, auth_headers, catalog_food
):
    owner, other = auth_headers(), auth_headers()
    own_id = str(uuid7())
    catalog_id = catalog_food
    original = client.put(f"/me/foods/{own_id}", headers=owner, json=own_food()).json()

    for food_id in (own_id, catalog_id):
        refused = client.put(
            f"/me/foods/{food_id}", headers=other, json=own_food(revision=2)
        )
        assert refused.status_code == 409

    assert (
        client.put(f"/me/foods/{own_id}", headers=owner, json=own_food()).json()
        == original
    )
    catalog = client.get("/foods", headers=owner, params={"q": "طعام عام"}).json()
    assert next(row for row in catalog if row["id"] == catalog_id)["own"] is False


@pytest.mark.parametrize(
    "change",
    [
        {"revision": 0},
        {"revision": 2_147_483_648},
        {"name_ar": None, "name_en": None},
        {"name_ar": "  "},
        {"name_en": "  "},
        {"name_en": "x" * 81},
        {"name_ar": "a\x00b"},
        {"calories": -0.1},
        {"calories": 900.1},
        {"protein": 100.1},
        {"carbs": -0.1},
        {"fat": 1.11},
        {"protein": 50, "carbs": 40, "fat": 10.1},
        {"barcode": "1234567"},
        {"barcode": "123456789012345"},
        {"barcode": "1234567a"},
        {"barcode": "12345678\n"},
    ],
)
def test_invalid_own_food_is_refused(client, auth_headers, change):
    response = client.put(
        f"/me/foods/{uuid7()}", headers=auth_headers(), json=own_food(**change)
    )
    assert response.status_code == 422


def test_english_only_food_accepts_range_edges_without_calorie_macro_rule(
    client, auth_headers
):
    body = own_food(
        name_ar=None,
        name_en="Rice",
        calories=900,
        protein=0,
        carbs=100,
        fat=0,
        barcode="12345678901234",
    )
    response = client.put(f"/me/foods/{uuid7()}", headers=auth_headers(), json=body)
    assert response.status_code == 201
    assert response.json()["calories"] == 900
    assert response.json()["barcode"] == "12345678901234"


def test_changed_own_food_is_pulled_without_an_entry(client, auth_headers):
    headers = auth_headers()
    food_id = str(uuid7())
    marker = client.get("/me/food-log/changes", headers=headers).json()["next_marker"]
    client.put(f"/me/foods/{food_id}", headers=headers, json=own_food())

    changed = client.get(
        "/me/food-log/changes", headers=headers, params={"since": marker}
    )
    assert [row["id"] for row in changed.json()["foods"]] == [food_id]


def test_entry_cannot_use_another_trainees_new_food(client, auth_headers):
    owner, other = auth_headers(), auth_headers()
    food_id = str(uuid7())
    client.put(f"/me/foods/{food_id}", headers=owner, json=own_food())
    body = {
        "revision": 1,
        "food_id": food_id,
        "meal": "lunch",
        "diary_day": "2026-11-22",
        "grams": 100,
        "logged_at": "2026-11-22T12:00:00+00:00",
        "per_100g": {"calories": 170, "protein": 8, "carbs": 15, "fat": 9},
        "totals": {"calories": 170, "protein": 8, "carbs": 15, "fat": 9},
    }

    refused = client.put(f"/me/food-log/entries/{uuid7()}", headers=other, json=body)
    accepted = client.put(f"/me/food-log/entries/{uuid7()}", headers=owner, json=body)

    assert refused.status_code == 422
    assert refused.json()["detail"][0]["type"] == "food_not_visible"
    assert accepted.status_code == 201
