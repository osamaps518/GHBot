import json
from datetime import UTC, datetime, timedelta
from uuid import uuid7

import pytest
from sqlalchemy import create_engine, text

from ghbot.config import Settings
from ghbot.food_log.application import put_entry
from ghbot.food_log.exceptions import EntryWriteFailed


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
        "grams": 150.0,
        "logged_at": "2026-11-22T12:00:00+00:00",
        "per_100g": {
            "calories": 130.0,
            "protein": 2.7,
            "carbs": 28.2,
            "fat": 0.3,
        },
        "totals": {
            "calories": 195.0,
            "protein": 4.1,
            "carbs": 42.3,
            "fat": 0.5,
        },
    }


def test_full_pull_returns_owned_entries_and_used_food(client, auth_headers, food):
    headers = auth_headers()
    item_id = str(uuid7())
    saved = client.put(
        f"/me/food-log/entries/{item_id}", headers=headers, json=entry(food)
    ).json()

    response = client.get("/me/food-log/changes", headers=headers)

    assert response.status_code == 200
    assert response.json()["entries"] == [saved]
    assert response.json()["foods"] == [
        {
            "id": food,
            "name_ar": "أرز",
            "name_en": None,
            "calories": 130.0,
            "protein": 2.7,
            "carbs": 28.2,
            "fat": 0.3,
            "barcode": None,
            "own": False,
            "revision": 0,
        }
    ]
    assert response.json()["next_marker"].endswith("Z")


def test_pull_returns_deleted_entry_and_excludes_other_trainee(
    client, auth_headers, food
):
    mine, other = auth_headers(), auth_headers()
    mine_id, other_id = str(uuid7()), str(uuid7())
    mine_url = f"/me/food-log/entries/{mine_id}"
    other_url = f"/me/food-log/entries/{other_id}"
    assert client.put(mine_url, headers=mine, json=entry(food)).status_code == 201
    assert client.put(other_url, headers=other, json=entry(food)).status_code == 201
    deleted = client.delete(mine_url, headers=mine).json()

    response = client.get("/me/food-log/changes", headers=mine)

    assert response.status_code == 200
    assert response.json()["entries"] == [deleted]
    assert response.json()["foods"][0]["id"] == food


def test_pull_filters_changed_foods_by_time_and_usage(
    client, auth_headers, engine, food
):
    mine, other, unused = auth_headers(), auth_headers(), auth_headers()
    mine_id, other_id = str(uuid7()), str(uuid7())
    client.put(f"/me/food-log/entries/{mine_id}", headers=mine, json=entry(food))
    client.put(f"/me/food-log/entries/{other_id}", headers=other, json=entry(food))
    marker = datetime.now(UTC) - timedelta(minutes=5)
    with engine.begin() as connection:
        connection.execute(
            text("UPDATE foods SET updated_at = :old WHERE id = :id"),
            {"old": marker - timedelta(seconds=1), "id": food},
        )
        connection.execute(
            text("UPDATE food_log_entries SET updated_at = :old WHERE id = :id"),
            {"old": marker - timedelta(seconds=1), "id": mine_id},
        )
    assert (
        client.get(
            "/me/food-log/changes", headers=mine, params={"since": marker.isoformat()}
        ).json()["foods"]
        == []
    )

    with engine.begin() as connection:
        connection.execute(
            text("UPDATE foods SET updated_at = :new WHERE id = :id"),
            {"new": marker + timedelta(seconds=1), "id": food},
        )
    assert [
        row["id"]
        for row in client.get(
            "/me/food-log/changes", headers=mine, params={"since": marker.isoformat()}
        ).json()["foods"]
    ] == [food]
    assert (
        client.get(
            "/me/food-log/changes", headers=unused, params={"since": marker.isoformat()}
        ).json()["foods"]
        == []
    )


def test_pull_returns_the_unchanged_food_of_a_changed_entry(
    client, auth_headers, engine, food
):
    headers = auth_headers()
    marker = datetime.now(UTC) - timedelta(minutes=5)
    with engine.begin() as connection:
        connection.execute(
            text("UPDATE foods SET updated_at = :old WHERE id = :id"),
            {"old": marker - timedelta(seconds=1), "id": food},
        )
    client.put(f"/me/food-log/entries/{uuid7()}", headers=headers, json=entry(food))

    response = client.get(
        "/me/food-log/changes", headers=headers, params={"since": marker.isoformat()}
    )

    assert [row["id"] for row in response.json()["foods"]] == [food]


def test_pull_returns_rows_inside_margin_and_skips_older_rows(
    client, auth_headers, engine, food
):
    headers = auth_headers()
    old_id = str(uuid7())
    assert (
        client.put(
            f"/me/food-log/entries/{old_id}", headers=headers, json=entry(food)
        ).status_code
        == 201
    )
    with engine.begin() as connection:
        connection.execute(
            text("""UPDATE food_log_entries
                 SET updated_at = now() - interval '5 minutes' WHERE id = :id"""),
            {"id": old_id},
        )
        before = connection.scalar(text("SELECT clock_timestamp()"))
    first = client.get("/me/food-log/changes", headers=headers).json()["next_marker"]
    second_id = str(uuid7())
    assert (
        client.put(
            f"/me/food-log/entries/{second_id}", headers=headers, json=entry(food)
        ).status_code
        == 201
    )
    with engine.begin() as connection:
        connection.execute(
            text("UPDATE food_log_entries SET updated_at = :time WHERE id = :id"),
            {"time": before, "id": second_id},
        )
    second = client.get(
        "/me/food-log/changes", headers=headers, params={"since": first}
    )
    assert [row["id"] for row in second.json()["entries"]] == [second_id]


def test_pull_rejects_marker_without_timezone(client, auth_headers):
    response = client.get(
        "/me/food-log/changes",
        headers=auth_headers(),
        params={"since": "2026-11-22T12:00:00"},
    )
    assert response.status_code == 422


def test_pull_never_returns_other_trainees_own_foods(client, auth_headers, engine):
    mine, other = auth_headers(), auth_headers()
    mine_user = client.get("/me", headers=mine).json()["id"]
    other_user = client.get("/me", headers=other).json()["id"]
    mine_food, other_food = uuid7(), uuid7()
    with engine.begin() as connection:
        connection.execute(
            text("""INSERT INTO foods (id, name_ar, source, owner_id, calories,
                 protein, carbs, fat) VALUES (:id, 'خاص', 'trainee', :owner,
                 100, 1, 2, 3)"""),
            [
                {"id": mine_food, "owner": mine_user},
                {"id": other_food, "owner": other_user},
            ],
        )
    mine_entry, other_entry = uuid7(), uuid7()
    try:
        assert (
            client.put(
                f"/me/food-log/entries/{mine_entry}",
                headers=mine,
                json=entry(str(mine_food)),
            ).status_code
            == 201
        )
        assert (
            client.put(
                f"/me/food-log/entries/{other_entry}",
                headers=other,
                json=entry(str(other_food)),
            ).status_code
            == 201
        )
        response = client.get("/me/food-log/changes", headers=mine)
        assert [row["id"] for row in response.json()["entries"]] == [str(mine_entry)]
        assert [row["id"] for row in response.json()["foods"]] == [str(mine_food)]
    finally:
        with engine.begin() as connection:
            connection.execute(
                text("DELETE FROM food_log_entries WHERE id IN (:mine, :other)"),
                {"mine": mine_entry, "other": other_entry},
            )
            connection.execute(
                text("DELETE FROM foods WHERE id IN (:mine, :other)"),
                {"mine": mine_food, "other": other_food},
            )


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
            150.0,
            {"calories": 130.0, "protein": 2.7, "carbs": 28.2, "fat": 0.3},
            {"calories": 195.0, "protein": 4.1, "carbs": 42.3, "fat": 0.5},
        ),
        (
            12.3,
            {"calories": 884.0, "protein": 0.0, "carbs": 0.0, "fat": 100.0},
            {"calories": 108.7, "protein": 0.0, "carbs": 0.0, "fat": 12.3},
        ),
        (
            2.5,
            {"calories": 130.0, "protein": 2.7, "carbs": 28.2, "fat": 0.3},
            {"calories": 3.3, "protein": 0.1, "carbs": 0.7, "fat": 0.0},
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
        assert response.json()["detail"] == [
            {
                "type": "food_not_visible",
                "loc": ["body", "food_id"],
                "msg": "Food is not visible",
                "input": str(food_id),
            }
        ]
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

    with pytest.raises(EntryWriteFailed):
        client.portal.call(fail_write)

    assert "DBAPIError" in caplog.text or "IntegrityError" in caplog.text
    assert secret_name not in caplog.text
    assert "171.37" not in caplog.text
