from datetime import date
from uuid import uuid4

from ghbot.profiles.router import utc_today
from ghbot.targets.calculation import calculate_targets


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
