from uuid import uuid4

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
