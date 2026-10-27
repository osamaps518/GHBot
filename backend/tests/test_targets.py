from uuid import uuid4

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
