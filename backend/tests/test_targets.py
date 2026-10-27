from datetime import date
from uuid import uuid4

import pytest

from ghbot.profiles.router import utc_today
from ghbot.targets import calculate_targets


@pytest.mark.parametrize(
    "profile, expected",
    [
        pytest.param(
            ("male", 30, 80, 180, "moderately_active", "lose"),
            (2210, 176, 49, 266, 2760, False),
            id="A-standard-deficit",
        ),
        pytest.param(
            ("female", 25, 60, 165, "lightly_active", "maintain"),
            (1850, 132, 41, 238, 1850, False),
            id="B-female-formula",
        ),
        pytest.param(
            ("female", 45, 52, 155, "sedentary", "lose"),
            (1200, 114, 27, 125, 1320, True),
            id="C-minimum",
        ),
        pytest.param(
            ("male", 22, 70, 175, "very_active", "gain"),
            (3200, 154, 71, 486, 2910, False),
            id="D-surplus",
        ),
        pytest.param(
            ("male", 35, 120, 175, "sedentary", "lose"),
            (2040, 168, 45, 241, 2550, False),
            id="E-reference-weight",
        ),
    ],
)
def test_agreed_worked_examples(profile, expected):
    targets = calculate_targets(*profile)

    assert (
        targets["calories"],
        targets["protein_g"],
        targets["fat_g"],
        targets["carbs_g"],
        targets["maintenance_calories"],
        targets["at_minimum"],
    ) == expected
    macro_calories = (
        targets["protein_g"] * 4 + targets["fat_g"] * 9 + targets["carbs_g"] * 4
    )
    assert abs(macro_calories - targets["calories"]) <= 5


def test_maintaining_weight_uses_rounded_calories_and_macros():
    targets = calculate_targets("male", 30, 80, 180, "sedentary", "maintain")

    assert targets == {
        "calories": 2140,
        "protein_g": 176,
        "fat_g": 48,
        "carbs_g": 251,
        "maintenance_calories": 2140,
        "at_minimum": False,
    }


def test_ties_round_half_up():
    targets = calculate_targets("male", 31, 80, 182, "sedentary", "maintain")

    assert targets == {
        "calories": 2150,
        "protein_g": 176,
        "fat_g": 48,
        "carbs_g": 254,
        "maintenance_calories": 2150,
        "at_minimum": False,
    }


def test_get_targets_without_profile_returns_404(client, auth_headers):
    response = client.get("/me/targets", headers=auth_headers(str(uuid4())))

    assert response.status_code == 404
    assert response.json() == {"detail": "Profile not found"}


def test_get_targets_uses_saved_profile_and_utc_age(app, client, auth_headers):
    app.dependency_overrides[utc_today] = lambda: date(2026, 10, 30)
    headers = auth_headers(str(uuid4()))
    profile = {
        "birth_year": 1996,
        "birth_month": 10,
        "sex": "male",
        "height_cm": 180,
        "weight_kg": 80,
        "activity_level": "extremely_active",
        "goal": "maintain",
    }
    assert client.put("/me/profile", headers=headers, json=profile).status_code == 201
    app.dependency_overrides[utc_today] = lambda: date(2026, 10, 31)

    response = client.get("/me/targets", headers=headers)

    assert response.status_code == 200
    assert response.json() == {
        "calories": 3380,
        "protein_g": 176,
        "fat_g": 75,
        "carbs_g": 500,
        "maintenance_calories": 3380,
        "at_minimum": False,
    }


def test_get_targets_requires_valid_token(client):
    for headers in ({}, {"Authorization": "Bearer invalid"}):
        response = client.get("/me/targets", headers=headers)

        assert response.status_code == 401
        assert response.json() == {"detail": "Not authenticated"}
