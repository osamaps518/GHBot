from datetime import date
from uuid import UUID

import pytest
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from ghbot.config import Settings
from ghbot.profiles import utc_today
from ghbot.targets.models import CustomTargets, TargetHistory


def save_profile(client, headers, *, sex="female", weight_kg=60, height_cm=165):
    return client.put(
        "/me/profile",
        headers=headers,
        json={
            "birth_year": 2000,
            "birth_month": 1,
            "sex": sex,
            "height_cm": height_cm,
            "weight_kg": weight_kg,
            "activity_level": "lightly_active",
            "goal": "maintain",
        },
    )


def test_save_custom_targets_returns_effective_and_recommended(
    app, client, auth_headers
):
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 28)
    headers = auth_headers()
    assert save_profile(client, headers).status_code == 201
    recommended = client.get("/me/targets", headers=headers).json()
    custom = {"calories": 1600, "protein_g": 100, "fat_g": 40, "carbs_g": 210}

    response = client.put("/me/targets/custom", headers=headers, json=custom)

    assert response.status_code == 200
    assert {key: response.json()[key] for key in custom} == custom
    assert response.json()["custom"] is True
    assert response.json()["macros_adjusted"] is False
    assert response.json()["recommended"] == recommended["recommended"]
    assert (
        response.json()["maintenance_calories"] == recommended["maintenance_calories"]
    )
    assert client.get("/me/targets", headers=headers).json() == response.json()


def test_save_rejects_minimum_and_macro_gap(app, client, auth_headers):
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 28)
    headers = auth_headers()
    assert save_profile(client, headers).status_code == 201
    baseline = {"calories": 1200, "protein_g": 100, "fat_g": 40, "carbs_g": 110}

    below = client.put(
        "/me/targets/custom", headers=headers, json={**baseline, "calories": 1199}
    )
    assert below.status_code == 422
    assert below.json()["detail"][0]["type"] == "below_minimum"

    allowed = client.put(
        "/me/targets/custom", headers=headers, json={**baseline, "fat_g": 51}
    )
    assert allowed.status_code == 200
    refused = client.put(
        "/me/targets/custom", headers=headers, json={**baseline, "carbs_g": 135}
    )
    assert refused.status_code == 422
    assert refused.json()["detail"][0]["type"] == "macros_mismatch"
    refused_below = client.put(
        "/me/targets/custom", headers=headers, json={**baseline, "calories": 1300}
    )
    assert refused_below.status_code == 422
    assert refused_below.json()["detail"][0]["type"] == "macros_mismatch"
    allowed = client.put(
        "/me/targets/custom", headers=headers, json={**baseline, "calories": 1299}
    )
    assert allowed.status_code == 200
    assert client.get("/me/targets", headers=headers).json() == allowed.json()


def test_reset_restores_recommended_and_records_only_real_changes(
    app, client, auth_headers
):
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 28)
    headers = auth_headers()
    assert save_profile(client, headers).status_code == 201
    recommended = client.get("/me/targets", headers=headers).json()
    first = {"calories": 1600, "protein_g": 100, "fat_g": 40, "carbs_g": 210}
    second = {"calories": 1700, "protein_g": 110, "fat_g": 40, "carbs_g": 225}
    assert (
        client.put("/me/targets/custom", headers=headers, json=first).status_code == 200
    )
    assert (
        client.put("/me/targets/custom", headers=headers, json=second).status_code
        == 200
    )

    reset = client.delete("/me/targets/custom", headers=headers)

    assert reset.status_code == 200
    assert reset.json() == recommended
    assert client.delete("/me/targets/custom", headers=headers).json() == recommended
    user_id = UUID(client.get("/me", headers=headers).json()["id"])
    with Session(create_engine(Settings().database_url.get_secret_value())) as session:
        rows = session.scalars(
            select(TargetHistory)
            .where(TargetHistory.user_id == user_id)
            .order_by(TargetHistory.id)
        ).all()
    assert [row.kind for row in rows] == ["manual_edit", "manual_edit", "reset"]
    assert [row.custom_calories for row in rows] == [1600, 1700, 1700]
    assert all(row.date == date(2026, 11, 28) for row in rows)
    assert all(row.recommended_calories == recommended["calories"] for row in rows)


def test_custom_targets_are_private_and_survive_profile_changes(
    app, client, auth_headers
):
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 28)
    alice, bob = auth_headers(), auth_headers()
    assert save_profile(client, alice).status_code == 201
    assert save_profile(client, bob).status_code == 201
    custom = {"calories": 1600, "protein_g": 100, "fat_g": 40, "carbs_g": 210}
    assert (
        client.put("/me/targets/custom", headers=alice, json=custom).status_code == 200
    )

    assert client.get("/me/targets", headers=bob).json()["custom"] is False
    assert client.delete("/me/targets/custom", headers=bob).json()["custom"] is False
    assert save_profile(client, alice, sex="male").status_code == 200
    own = client.get("/me/targets", headers=alice).json()
    assert own["custom"] is True
    assert own["calories"] == 1600
    assert (
        own["recommended"]
        != client.get("/me/targets", headers=bob).json()["recommended"]
    )


def test_read_raises_older_custom_targets_to_minimum(app, client, auth_headers):
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 28)
    headers = auth_headers()
    assert save_profile(client, headers, weight_kg=60).status_code == 201
    user_id = UUID(client.get("/me", headers=headers).json()["id"])
    with Session(create_engine(Settings().database_url.get_secret_value())) as session:
        session.add(
            CustomTargets(
                user_id=user_id, calories=1100, protein_g=85, fat_g=24, carbs_g=136
            )
        )
        session.commit()

    response = client.get("/me/targets", headers=headers)

    assert response.status_code == 200
    assert {
        key: response.json()[key]
        for key in ("calories", "protein_g", "fat_g", "carbs_g")
    } == {"calories": 1200, "protein_g": 96, "fat_g": 27, "carbs_g": 143}
    assert response.json()["custom"] is True
    assert response.json()["macros_adjusted"] is True
    assert response.json()["at_minimum"] is True


def test_read_rounds_filled_carbs_half_up(app, client, auth_headers):
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 28)
    headers = auth_headers()
    assert save_profile(client, headers, weight_kg=60).status_code == 201
    user_id = UUID(client.get("/me", headers=headers).json()["id"])
    with Session(create_engine(Settings().database_url.get_secret_value())) as session:
        session.add(
            CustomTargets(
                user_id=user_id, calories=1100, protein_g=85, fat_g=29, carbs_g=125
            )
        )
        session.commit()

    response = client.get("/me/targets", headers=headers)

    assert {
        key: response.json()[key]
        for key in ("calories", "protein_g", "fat_g", "carbs_g")
    } == {"calories": 1200, "protein_g": 96, "fat_g": 29, "carbs_g": 139}


def test_read_uses_bmi_25_weight_and_reduces_carbs_when_needed(
    app, client, auth_headers
):
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 28)
    headers = auth_headers()
    assert (
        save_profile(
            client, headers, sex="male", weight_kg=120, height_cm=175
        ).status_code
        == 201
    )
    user_id = UUID(client.get("/me", headers=headers).json()["id"])
    with Session(create_engine(Settings().database_url.get_secret_value())) as session:
        session.add(
            CustomTargets(
                user_id=user_id, calories=1400, protein_g=100, fat_g=30, carbs_g=183
            )
        )
        session.commit()

    response = client.get("/me/targets", headers=headers)

    assert {
        key: response.json()[key]
        for key in ("calories", "protein_g", "fat_g", "carbs_g")
    } == {"calories": 1500, "protein_g": 123, "fat_g": 33, "carbs_g": 178}


def test_profile_change_preserves_custom_row_and_applies_new_minimum(
    app, client, auth_headers
):
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 28)
    headers = auth_headers()
    assert save_profile(client, headers).status_code == 201
    values = {"calories": 1200, "protein_g": 96, "fat_g": 27, "carbs_g": 143}
    assert (
        client.put("/me/targets/custom", headers=headers, json=values).status_code
        == 200
    )

    assert save_profile(client, headers, sex="male").status_code == 200
    adjusted = client.get("/me/targets", headers=headers).json()

    assert adjusted["custom"] is True
    assert adjusted["macros_adjusted"] is True
    assert adjusted["at_minimum"] is True
    assert adjusted["calories"] == 1500
    assert (
        client.delete("/me/targets/custom", headers=headers).json()["custom"] is False
    )


def test_raised_calories_with_unchanged_macros_are_not_macros_adjusted(
    app, client, auth_headers
):
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 28)
    headers = auth_headers()
    assert save_profile(client, headers).status_code == 201
    values = {"calories": 1450, "protein_g": 100, "fat_g": 50, "carbs_g": 163}
    assert (
        client.put("/me/targets/custom", headers=headers, json=values).status_code
        == 200
    )

    assert save_profile(client, headers, sex="male").status_code == 200
    adjusted = client.get("/me/targets", headers=headers).json()

    assert {key: adjusted[key] for key in values} == {**values, "calories": 1500}
    assert adjusted["at_minimum"] is True
    assert adjusted["macros_adjusted"] is False


@pytest.mark.parametrize("sex, floor", [("female", 1200), ("male", 1500)])
def test_each_profile_sex_enforces_its_minimum_on_save(
    app, client, auth_headers, sex, floor
):
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 28)
    headers = auth_headers()
    assert save_profile(client, headers, sex=sex).status_code == 201
    body = {"calories": floor - 1, "protein_g": 100, "fat_g": 40, "carbs_g": 185}

    response = client.put("/me/targets/custom", headers=headers, json=body)

    assert response.status_code == 422
    assert response.json()["detail"][0]["type"] == "below_minimum"
    assert response.json()["detail"][0]["ctx"] == {"minimum": floor}
    assert client.get("/me/targets", headers=headers).json()["custom"] is False
