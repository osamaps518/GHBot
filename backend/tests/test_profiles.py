import json
import logging
import math
from concurrent.futures import ThreadPoolExecutor
from datetime import date
from threading import Barrier
from uuid import UUID, uuid4

import pytest
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.exc import DBAPIError

from ghbot.profiles import Profile, utc_today

PROFILE = {
    "birth_year": 1998,
    "birth_month": 4,
    "sex": "female",
    "height_cm": 167.5,
    "weight_kg": 63.25,
    "activity_level": "moderately_active",
    "goal": "maintain",
}


def test_failed_profile_insert_does_not_log_health_values(client, caplog):
    # A missing user makes Postgres reject this profile insert. The bound
    # height must stay out of the exception that a server would log.
    height = float("171.37")

    async def fail_insert():
        async with client.app_state["sessions"]() as session:
            await session.execute(
                insert(Profile).values(
                    user_id=uuid4(), **{**PROFILE, "height_cm": height}
                )
            )

    with pytest.raises(DBAPIError):
        try:
            client.portal.call(fail_insert)
        except DBAPIError:
            logging.getLogger("ghbot.test").exception("Profile insert failed")
            raise

    assert "171.37" not in caplog.text


def test_get_missing_profile_returns_404(client, auth_headers):
    response = client.get("/me/profile", headers=auth_headers())

    assert response.status_code == 404
    assert response.json() == {"detail": "Profile not found"}


def test_put_creates_profile_and_get_returns_it(client, auth_headers):
    headers = auth_headers()

    saved = client.put("/me/profile", headers=headers, json=PROFILE)

    assert saved.status_code == 201
    assert saved.json() == PROFILE
    loaded = client.get("/me/profile", headers=headers)
    assert loaded.status_code == 200
    assert loaded.json() == PROFILE


def test_second_put_replaces_whole_profile(client, auth_headers):
    headers = auth_headers()
    client.put("/me/profile", headers=headers, json=PROFILE)
    changed = {**PROFILE, "weight_kg": 70.75, "goal": "lose"}

    response = client.put("/me/profile", headers=headers, json=changed)

    assert response.status_code == 200
    assert response.json() == changed
    assert client.get("/me/profile", headers=headers).json() == changed


def test_profiles_are_private_to_each_user(client, auth_headers):
    alice = auth_headers()
    bob = auth_headers()
    bob_profile = {**PROFILE, "height_cm": 181.25}
    assert client.put("/me/profile", headers=alice, json=PROFILE).status_code == 201

    assert client.get("/me/profile", headers=bob).status_code == 404
    assert client.put("/me/profile", headers=bob, json=bob_profile).status_code == 201
    assert client.get("/me/profile", headers=alice).json() == PROFILE
    assert client.get("/me/profile", headers=bob).json() == bob_profile


def test_profile_owner_cannot_be_changed_by_body_ids(app, client, auth_headers):
    app.dependency_overrides[utc_today] = lambda: date(2026, 10, 31)
    alice = auth_headers()
    bob = auth_headers()
    alice_id = client.get("/me", headers=alice).json()["id"]
    alice_profile = {
        **PROFILE,
        "birth_year": 1996,
        "birth_month": 10,
        "sex": "male",
        "height_cm": 180,
        "weight_kg": 80,
        "activity_level": "moderately_active",
        "goal": "lose",
    }
    bob_profile = {
        **PROFILE,
        "birth_year": 2001,
        "birth_month": 10,
        "sex": "female",
        "height_cm": 165,
        "weight_kg": 60,
        "activity_level": "lightly_active",
        "goal": "gain",
    }
    assert (
        client.put("/me/profile", headers=alice, json=alice_profile).status_code == 201
    )
    assert client.put("/me/profile", headers=bob, json=bob_profile).status_code == 201

    changed = {**bob_profile, "goal": "maintain"}
    response = client.put(
        "/me/profile",
        headers=bob,
        json={**changed, "id": alice_id, "user_id": alice_id},
    )

    assert response.status_code == 200
    assert client.get("/me/profile", headers=alice).json() == alice_profile
    assert client.get("/me/profile", headers=bob).json() == changed
    assert client.get("/me/targets", headers=alice).json()["calories"] == 2210
    assert client.get("/me/targets", headers=bob).json()["calories"] == 1850


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
        pytest.param(
            {**PROFILE, "activity_level": "active"}, id="activity_level=active"
        ),
        pytest.param({**PROFILE, "goal": "bulk"}, id="goal=bulk"),
        pytest.param(
            {k: v for k, v in PROFILE.items() if k != "birth_year"},
            id="birth_year=missing",
        ),
    ],
)
def test_invalid_put_does_not_replace_saved_profile(client, auth_headers, invalid):
    headers = auth_headers()
    assert client.put("/me/profile", headers=headers, json=PROFILE).status_code == 201

    response = client.put("/me/profile", headers=headers, json=invalid)

    assert response.status_code == 422
    assert client.get("/me/profile", headers=headers).json() == PROFILE


@pytest.mark.parametrize(
    ("height_cm", "sent"),
    [(math.nan, "NaN"), (math.inf, "Infinity"), (-math.inf, "-Infinity")],
)
def test_non_finite_number_gives_422(client, auth_headers, height_cm, sent):
    headers = auth_headers()
    # json= in the test client refuses NaN and Infinity, so send the raw text.
    body = json.dumps({**PROFILE, "height_cm": height_cm})

    response = client.put(
        "/me/profile",
        headers={**headers, "Content-Type": "application/json"},
        content=body,
    )

    assert response.status_code == 422
    assert response.json()["detail"][0]["loc"] == ["body", "height_cm"]
    assert response.json()["detail"][0]["input"] == sent
    assert client.get("/me/profile", headers=headers).status_code == 404


def test_non_finite_numbers_nested_in_error_input_give_422(client):
    response = client.post(
        "/dev/token",
        headers={"Content-Type": "application/json"},
        content='{"subject":{"nested":[NaN,Infinity,-Infinity,1.5]}}',
    )

    assert response.status_code == 422
    assert response.json() == {
        "detail": [
            {
                "type": "string_type",
                "loc": ["body", "subject"],
                "msg": "Input should be a valid string",
                "input": {"nested": ["NaN", "Infinity", "-Infinity", 1.5]},
            }
        ]
    }


@pytest.mark.parametrize(
    "profile",
    [
        {**PROFILE, "birth_month": 1, "height_cm": 130, "weight_kg": 35},
        {**PROFILE, "birth_month": 12, "height_cm": 220, "weight_kg": 250},
    ],
)
def test_range_limits_are_accepted(client, auth_headers, profile):
    response = client.put("/me/profile", headers=auth_headers(), json=profile)

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

    response = client.put("/me/profile", headers=auth_headers(), json=profile)

    assert response.status_code == 201
    assert response.json()[field] == code


@pytest.mark.parametrize(
    ("today", "birth_year", "birth_month", "expected"),
    [
        (date(2026, 10, 25), 2008, 10, 422),  # Could still be 17.
        (date(2026, 10, 25), 2008, 9, 201),
        (date(2026, 10, 31), 2008, 10, 201),  # Exactly 18.
        (date(2026, 10, 31), 1926, 10, 201),  # Exactly 100.
        (date(2026, 10, 25), 1925, 11, 201),  # Still 100.
        (date(2026, 10, 31), 1925, 10, 422),  # Now 101.
        (date(2026, 10, 25), 2026, 11, 422),  # Future birth month.
    ],
)
def test_age_is_checked_at_save_using_last_day_of_birth_month(
    app, client, auth_headers, today, birth_year, birth_month, expected
):
    app.dependency_overrides[utc_today] = lambda: today
    headers = auth_headers()
    profile = {**PROFILE, "birth_year": birth_year, "birth_month": birth_month}

    response = client.put("/me/profile", headers=headers, json=profile)

    assert response.status_code == expected
    if expected == 201:
        assert response.json() == profile
    else:
        assert response.json()["detail"][0]["type"] == "age_out_of_range"
        assert response.json()["detail"][0]["msg"] == "Age must be between 18 and 100"
        assert response.json()["detail"][0]["loc"] == ["body", "birth_year"]
        assert client.get("/me/profile", headers=headers).status_code == 404


def test_get_keeps_saved_profile_after_user_turns_101(app, client, auth_headers):
    app.dependency_overrides[utc_today] = lambda: date(2026, 10, 25)
    headers = auth_headers()
    profile = {**PROFILE, "birth_year": 1925, "birth_month": 11}
    assert client.put("/me/profile", headers=headers, json=profile).status_code == 201
    app.dependency_overrides[utc_today] = lambda: date(2026, 11, 30)

    response = client.get("/me/profile", headers=headers)

    assert response.status_code == 200
    assert response.json() == profile


def test_old_saved_value_outside_current_range_still_reads(client, auth_headers):
    headers = auth_headers()
    user_id = UUID(client.get("/me", headers=headers).json()["id"])
    saved = {**PROFILE, "height_cm": 229.0}

    async def insert_old_profile():
        async with client.app_state["sessions"]() as session:
            await session.execute(insert(Profile).values(user_id=user_id, **saved))
            await session.commit()

    client.portal.call(insert_old_profile)

    response = client.get("/me/profile", headers=headers)
    assert response.status_code == 200
    assert response.json() == saved
    assert client.get("/me/targets", headers=headers).status_code == 200
    assert client.put("/me/profile", headers=headers, json=saved).status_code == 422


@pytest.mark.parametrize("method", ["get", "put"])
@pytest.mark.parametrize("headers", [{}, {"Authorization": "Bearer invalid"}])
def test_profile_endpoints_require_valid_token(client, method, headers):
    response = client.request(method, "/me/profile", headers=headers, json=PROFILE)

    assert response.status_code == 401
    assert response.json() == {"detail": "Not authenticated"}


def test_concurrent_first_saves_share_one_profile(client, auth_headers):
    headers = auth_headers()
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
