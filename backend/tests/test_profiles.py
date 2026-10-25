from concurrent.futures import ThreadPoolExecutor
from datetime import date
from threading import Barrier
from uuid import uuid4

import pytest

from ghbot.profiles.router import utc_today

PROFILE = {
    "birth_year": 1998,
    "birth_month": 4,
    "sex": "female",
    "height_cm": 167.5,
    "weight_kg": 63.25,
    "activity_level": "moderately_active",
    "goal": "maintain",
}


def test_get_missing_profile_returns_404(client, auth_headers):
    response = client.get("/me/profile", headers=auth_headers(str(uuid4())))

    assert response.status_code == 404
    assert response.json() == {"detail": "Profile not found"}


def test_put_creates_profile_and_get_returns_it(client, auth_headers):
    headers = auth_headers(str(uuid4()))

    saved = client.put("/me/profile", headers=headers, json=PROFILE)

    assert saved.status_code == 201
    assert saved.json() == PROFILE
    loaded = client.get("/me/profile", headers=headers)
    assert loaded.status_code == 200
    assert loaded.json() == PROFILE


def test_second_put_replaces_whole_profile(client, auth_headers):
    headers = auth_headers(str(uuid4()))
    client.put("/me/profile", headers=headers, json=PROFILE)
    changed = {**PROFILE, "weight_kg": 70.75, "goal": "lose"}

    response = client.put("/me/profile", headers=headers, json=changed)

    assert response.status_code == 200
    assert response.json() == changed
    assert client.get("/me/profile", headers=headers).json() == changed


def test_profiles_are_private_to_each_user(client, auth_headers):
    alice = auth_headers(str(uuid4()))
    bob = auth_headers(str(uuid4()))
    bob_profile = {**PROFILE, "height_cm": 181.25}
    assert client.put("/me/profile", headers=alice, json=PROFILE).status_code == 201

    assert client.get("/me/profile", headers=bob).status_code == 404
    assert client.put("/me/profile", headers=bob, json=bob_profile).status_code == 201
    assert client.get("/me/profile", headers=alice).json() == PROFILE
    assert client.get("/me/profile", headers=bob).json() == bob_profile


@pytest.mark.parametrize(
    "invalid",
    [
        pytest.param({**PROFILE, "height_cm": 129.9}, id="height_cm=129.9"),
        pytest.param({**PROFILE, "height_cm": 220.1}, id="height_cm=220.1"),
        pytest.param({**PROFILE, "weight_kg": 34.9}, id="weight_kg=34.9"),
        pytest.param({**PROFILE, "weight_kg": 250.1}, id="weight_kg=250.1"),
        pytest.param({**PROFILE, "weight_kg": 251}, id="weight_kg=251"),
        pytest.param({**PROFILE, "birth_month": 0}, id="birth_month=0"),
        pytest.param({**PROFILE, "birth_month": 13}, id="birth_month=13"),
        pytest.param({**PROFILE, "sex": "other"}, id="sex=other"),
        pytest.param({**PROFILE, "activity_level": "active"}, id="activity_level=active"),
        pytest.param({**PROFILE, "goal": "bulk"}, id="goal=bulk"),
        pytest.param(
            {k: v for k, v in PROFILE.items() if k != "birth_year"},
            id="birth_year=missing",
        ),
    ],
)
def test_invalid_put_does_not_replace_saved_profile(client, auth_headers, invalid):
    headers = auth_headers(str(uuid4()))
    assert client.put("/me/profile", headers=headers, json=PROFILE).status_code == 201

    response = client.put("/me/profile", headers=headers, json=invalid)

    assert response.status_code == 422
    assert client.get("/me/profile", headers=headers).json() == PROFILE


@pytest.mark.parametrize(
    "profile",
    [
        {**PROFILE, "birth_month": 1, "height_cm": 130, "weight_kg": 35},
        {**PROFILE, "birth_month": 12, "height_cm": 220, "weight_kg": 250},
    ],
)
def test_range_limits_are_accepted(client, auth_headers, profile):
    response = client.put(
        "/me/profile", headers=auth_headers(str(uuid4())), json=profile
    )

    assert response.status_code == 201
    assert response.json() == profile


@pytest.mark.parametrize(
    ("field", "code"),
    [
        ("sex", "male"),
        ("sex", "female"),
        ("activity_level", "sedentary"),
        ("activity_level", "lightly_active"),
        ("activity_level", "moderately_active"),
        ("activity_level", "very_active"),
        ("activity_level", "extremely_active"),
        ("goal", "lose"),
        ("goal", "maintain"),
        ("goal", "gain"),
    ],
)
def test_agreed_choice_codes_are_accepted(client, auth_headers, field, code):
    profile = {**PROFILE, field: code}

    response = client.put(
        "/me/profile", headers=auth_headers(str(uuid4())), json=profile
    )

    assert response.status_code == 201
    assert response.json()[field] == code


@pytest.mark.parametrize(
    ("today", "birth_year", "birth_month", "expected"),
    [
        (date(2026, 10, 25), 2008, 10, 422),  # Could still be 17.
        (date(2026, 10, 25), 2008, 9, 201),
        (date(2026, 10, 31), 2008, 10, 201),  # Exactly 18.
        (date(2026, 10, 31), 1946, 10, 201),  # Exactly 80.
        (date(2026, 10, 25), 1945, 11, 201),  # Still 80.
        (date(2026, 10, 31), 1945, 10, 422),  # Now 81.
        (date(2026, 10, 25), 2026, 11, 422),  # Future birth month.
    ],
)
def test_age_is_checked_at_save_using_last_day_of_birth_month(
    app, client, auth_headers, today, birth_year, birth_month, expected
):
    app.dependency_overrides[utc_today] = lambda: today
    headers = auth_headers(str(uuid4()))
    profile = {**PROFILE, "birth_year": birth_year, "birth_month": birth_month}

    response = client.put("/me/profile", headers=headers, json=profile)

    assert response.status_code == expected
    if expected == 201:
        assert response.json() == profile
    else:
        assert client.get("/me/profile", headers=headers).status_code == 404


def test_get_keeps_saved_profile_after_user_turns_81(app, client, auth_headers):
    app.dependency_overrides[utc_today] = lambda: date(2026, 10, 25)
    headers = auth_headers(str(uuid4()))
    profile = {**PROFILE, "birth_year": 1945, "birth_month": 11}
    assert client.put("/me/profile", headers=headers, json=profile).status_code == 201
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 30)

    response = client.get("/me/profile", headers=headers)

    assert response.status_code == 200
    assert response.json() == profile


@pytest.mark.parametrize("method", ["get", "put"])
@pytest.mark.parametrize("headers", [{}, {"Authorization": "Bearer invalid"}])
def test_profile_endpoints_require_valid_token(client, method, headers):
    response = client.request(method, "/me/profile", headers=headers, json=PROFILE)

    assert response.status_code == 401
    assert response.json() == {"detail": "Not authenticated"}


def test_concurrent_first_saves_share_one_profile(client, auth_headers):
    headers = auth_headers(str(uuid4()))
    start = Barrier(2)
    first = {**PROFILE, "weight_kg": 61.5}
    second = {**PROFILE, "weight_kg": 72.5}

    def save(profile):
        start.wait(timeout=10)
        return client.put("/me/profile", headers=headers, json=profile)

    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(save, profile) for profile in (first, second)]
        responses = [future.result(timeout=10) for future in futures]

    assert sorted(response.status_code for response in responses) == [200, 201]
    assert client.get("/me/profile", headers=headers).json() in (first, second)
