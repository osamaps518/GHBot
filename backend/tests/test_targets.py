from datetime import date
from typing import get_args

import pytest

from ghbot.profiles import ActivityLevel, Goal, ProfileSnapshot, utc_today
from ghbot.targets import calculate_targets
from ghbot.targets.application import ACTIVITY_FACTORS, GOAL_FACTORS


def test_every_profile_code_has_a_target_factor():
    assert set(get_args(ActivityLevel)) == set(ACTIVITY_FACTORS)
    assert set(get_args(Goal)) == set(GOAL_FACTORS)


def target_for(sex, age, weight_kg, height_cm, activity_level, goal):
    return calculate_targets(
        ProfileSnapshot(
            birth_year=2026 - age,
            birth_month=1,
            sex=sex,
            height_cm=height_cm,
            weight_kg=weight_kg,
            activity_level=activity_level,
            goal=goal,
            age=age,
        )
    )


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
    targets = target_for(*profile)

    assert targets["goal"] == profile[-1]
    assert (
        targets["goal_adjustment_percent"]
        == {"lose": -20, "maintain": 0, "gain": 10}[profile[-1]]
    )

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
    targets = target_for("male", 30, 80, 180, "sedentary", "maintain")

    assert targets == {
        "calories": 2140,
        "protein_g": 176,
        "fat_g": 48,
        "carbs_g": 251,
        "maintenance_calories": 2140,
        "at_minimum": False,
        "above_tested_age": False,
        "goal": "maintain",
        "goal_adjustment_percent": 0,
    }


def test_ties_round_half_up():
    targets = target_for("male", 31, 80, 182, "sedentary", "maintain")

    assert targets == {
        "calories": 2150,
        "protein_g": 176,
        "fat_g": 48,
        "carbs_g": 254,
        "maintenance_calories": 2150,
        "at_minimum": False,
        "above_tested_age": False,
        "goal": "maintain",
        "goal_adjustment_percent": 0,
    }


def test_get_targets_without_profile_returns_404(client, auth_headers):
    response = client.get("/me/targets", headers=auth_headers())

    assert response.status_code == 404
    assert response.json() == {"detail": "Profile not found"}


def test_get_targets_uses_saved_profile_and_utc_age(app, client, auth_headers):
    app.dependency_overrides[utc_today] = lambda: date(2026, 10, 30)
    headers = auth_headers()
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
        "above_tested_age": False,
        "goal": "maintain",
        "goal_adjustment_percent": 0,
    }


@pytest.mark.parametrize(
    "today, above_tested_age",
    [
        pytest.param(date(2026, 10, 30), False, id="78-day-before-birthday"),
        pytest.param(date(2026, 10, 31), True, id="79-on-birthday"),
    ],
)
def test_get_targets_flags_ages_above_78(
    app, client, auth_headers, today, above_tested_age
):
    # The birthday is the last day of the birth month: 31 October.
    app.dependency_overrides[utc_today] = lambda: today
    headers = auth_headers()
    profile = {
        "birth_year": 1947,
        "birth_month": 10,
        "sex": "female",
        "height_cm": 160,
        "weight_kg": 60,
        "activity_level": "sedentary",
        "goal": "maintain",
    }
    assert client.put("/me/profile", headers=headers, json=profile).status_code == 201

    response = client.get("/me/targets", headers=headers)

    assert response.status_code == 200
    assert response.json()["above_tested_age"] is above_tested_age


def test_get_targets_requires_valid_token(client):
    for headers in ({}, {"Authorization": "Bearer invalid"}):
        response = client.get("/me/targets", headers=headers)

        assert response.status_code == 401
        assert response.json() == {"detail": "Not authenticated"}
