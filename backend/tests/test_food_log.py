import json
from uuid import uuid7

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine, text

from ghbot.config import Settings
from ghbot.food_log.application import put_entry


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
        "id": url.rsplit("/", 1)[1],
        "revision": 0,
        "deleted": True,
        "food_id": None,
        "meal": None,
        "meal_name": None,
        "diary_day": None,
        "grams": None,
        "logged_at": None,
        "per_100g": None,
        "totals": None,
    }
    assert late.status_code == 200
    assert late.json() == deleted.json()


@pytest.mark.parametrize(
    ("grams", "per_100g", "totals"),
    [
        (
            "150",
            {"calories": "130.0", "protein": "2.7", "carbs": "28.2", "fat": "0.3"},
            {"calories": "195.0", "protein": "4.1", "carbs": "42.3", "fat": "0.5"},
        ),
        (
            "12.3",
            {"calories": "884.0", "protein": "0", "carbs": "0", "fat": "100.0"},
            {"calories": "108.7", "protein": "0.0", "carbs": "0.0", "fat": "12.3"},
        ),
        (
            "2.5",
            {"calories": "130.0", "protein": "2.7", "carbs": "28.2", "fat": "0.3"},
            {"calories": "3.3", "protein": "0.1", "carbs": "0.7", "fat": "0.0"},
        ),
    ],
)
def test_worked_number_examples_are_accepted(
    client, auth_headers, food, grams, per_100g, totals
):
    body = {**entry(food), "grams": grams, "per_100g": per_100g, "totals": totals}

    response = client.put(
        f"/me/food-log/entries/{uuid7()}", headers=auth_headers(), json=body
    )

    assert response.status_code == 201
    assert response.json()["totals"] == totals


def test_entry_sent_as_json_numbers(client, auth_headers, food):
    body = {
        **entry(food),
        "grams": 150.0,
        "per_100g": {
            "calories": 130.0,
            "protein": 2.7,
            "carbs": 28.2,
            "fat": 0.3,
        },
        "totals": {"calories": 195.0, "protein": 4.1, "carbs": 42.3, "fat": 0.5},
    }
    headers = auth_headers()

    accepted = client.put(f"/me/food-log/entries/{uuid7()}", headers=headers, json=body)
    refused = client.put(
        f"/me/food-log/entries/{uuid7()}",
        headers=headers,
        json={**body, "grams": 1.11},
    )

    assert accepted.status_code == 201
    assert refused.status_code == 422


@pytest.mark.parametrize(
    "change",
    [
        {"revision": 0},
        {"revision": 2147483648},
        {"grams": "0"},
        {"grams": "5000.1"},
        {"grams": "1.11"},
        {
            "per_100g": {
                "calories": "900.1",
                "protein": "2.7",
                "carbs": "28.2",
                "fat": "0.3",
            }
        },
        {
            "per_100g": {
                "calories": "130",
                "protein": "100.1",
                "carbs": "28.2",
                "fat": "0.3",
            }
        },
        {
            "per_100g": {
                "calories": "130",
                "protein": "-1",
                "carbs": "28.2",
                "fat": "0.3",
            }
        },
        {
            "per_100g": {
                "calories": "130",
                "protein": "2.77",
                "carbs": "28.2",
                "fat": "0.3",
            }
        },
        {
            "totals": {
                "calories": "195.0",
                "protein": "4.0",
                "carbs": "42.3",
                "fat": "0.5",
            }
        },
        {"logged_at": "2026-11-22T12:00:00"},
        {"meal": "extra", "meal_name": None},
        {"meal": "extra", "meal_name": "   "},
        {"meal": "extra", "meal_name": "x" * 41},
        {"meal": "extra", "meal_name": "a\x00b"},
        {"meal": "lunch", "meal_name": "Snack"},
    ],
)
def test_invalid_entry_is_refused(client, auth_headers, food, change):
    body = {**entry(food), **change}

    response = client.put(
        f"/me/food-log/entries/{uuid7()}", headers=auth_headers(), json=body
    )

    assert response.status_code == 422


def test_lone_surrogate_in_meal_name_is_refused(client, auth_headers, food):
    body = json.dumps({**entry(food), "meal": "extra", "meal_name": "Snack"})
    body = body.replace('"meal_name": "Snack"', r'"meal_name": "\ud800"')

    response = client.put(
        f"/me/food-log/entries/{uuid7()}",
        headers={**auth_headers(), "Content-Type": "application/json"},
        content=body,
    )

    assert response.status_code == 422


def test_extra_meal_with_name_is_accepted(client, auth_headers, food):
    body = {**entry(food), "meal": "extra", "meal_name": "Evening snack"}

    response = client.put(
        f"/me/food-log/entries/{uuid7()}", headers=auth_headers(), json=body
    )

    assert response.status_code == 201
    assert response.json()["meal_name"] == "Evening snack"


def test_regular_meal_can_omit_name(client, auth_headers, food):
    body = entry(food)
    del body["meal_name"]

    response = client.put(
        f"/me/food-log/entries/{uuid7()}", headers=auth_headers(), json=body
    )

    assert response.status_code == 201
    assert response.json()["meal_name"] is None


def test_other_trainees_own_food_cannot_be_logged(client, auth_headers, engine):
    owner = auth_headers()
    other = auth_headers()
    owner_id = client.get("/me", headers=owner).json()["id"]
    food_id = uuid7()
    with engine.begin() as connection:
        connection.execute(
            text("""INSERT INTO foods (id, name_ar, source, owner_id, calories,
                     protein, carbs, fat) VALUES (:id, 'خاص', 'trainee', :owner,
                     130, 2.7, 28.2, 0.3)"""),
            {"id": food_id, "owner": owner_id},
        )
    try:
        response = client.put(
            f"/me/food-log/entries/{uuid7()}",
            headers=other,
            json=entry(str(food_id)),
        )
        assert response.status_code == 422
    finally:
        with engine.begin() as connection:
            connection.execute(
                text("DELETE FROM foods WHERE id = :id"), {"id": food_id}
            )


def test_failed_write_keeps_entry_values_out_of_logs(
    client, auth_headers, food, caplog
):
    headers = auth_headers()
    user_id = client.get("/me", headers=headers).json()["id"]
    secret_name = "Private health note 171.37"

    async def fail_write():
        async with client.app_state["sessions"]() as session:
            values = {
                "revision": 1,
                "food_id": food,
                "meal": "lunch",
                "meal_name": secret_name,
                "diary_day": "2026-11-22",
                "grams": "150.0",
                "logged_at": "2026-11-22T12:00:00+00:00",
                "calories_per_100g": "130.0",
                "protein_per_100g": "2.7",
                "carbs_per_100g": "28.2",
                "fat_per_100g": "0.3",
                "calories": "195.0",
                "protein": "4.1",
                "carbs": "42.3",
                "fat": "0.5",
            }
            await put_entry(session, user_id, uuid7(), values)

    with pytest.raises(HTTPException) as error:
        client.portal.call(fail_write)

    assert error.value.status_code == 500
    assert "DBAPIError" in caplog.text or "IntegrityError" in caplog.text
    assert secret_name not in caplog.text
    assert "171.37" not in caplog.text
