from uuid import uuid7

import pytest
from sqlalchemy import create_engine, text

from ghbot.config import Settings
from ghbot.foods import visible_foods


@pytest.fixture
def food_rows():
    engine = create_engine(Settings().database_url.get_secret_value())
    ids = []

    def add(name_ar, name_en=None, other_names=None, owner_id=None, **nutrients):
        food_id = uuid7()
        ids.append(food_id)
        with engine.begin() as connection:
            connection.execute(
                text("""
                    INSERT INTO foods (id, name_ar, name_en, other_names, source,
                                       source_id, owner_id, calories, protein, carbs, fat)
                    VALUES (:id, :name_ar, :name_en, :other_names,
                            :source, :source_id, :owner_id,
                            :calories, :protein, :carbs, :fat)
                """),
                {
                    "id": food_id,
                    "name_ar": name_ar,
                    "name_en": name_en,
                    "other_names": other_names or [],
                    "source": "trainee" if owner_id else "regional",
                    "source_id": None if owner_id else str(food_id),
                    "owner_id": owner_id,
                    "calories": nutrients.get("calories", 100),
                    "protein": nutrients.get("protein", 1),
                    "carbs": nutrients.get("carbs", 2),
                    "fat": nutrients.get("fat", 3),
                },
            )
        return str(food_id)

    yield add

    with engine.begin() as connection:
        connection.execute(text("DELETE FROM foods WHERE id = ANY(:ids)"), {"ids": ids})
    engine.dispose()


def test_generated_search_cleans_names_on_insert(food_rows):
    food_id = food_rows("مقلوبة", "Crème caramel", ["ﻣﻘﻠﻮﺑﺔ"])
    engine = create_engine(Settings().database_url.get_secret_value())
    with engine.connect() as connection:
        search = connection.execute(
            text("SELECT search FROM foods WHERE id = :id"), {"id": food_id}
        ).scalar_one()
    engine.dispose()

    assert search == "مقلوبه | creme caramel | مقلوبه"


def test_search_column_fills_with_an_empty_search_path():
    """Mirror the empty search path used when pg_dump restores rows."""
    engine = create_engine(Settings().database_url.get_secret_value())
    with engine.connect() as connection:
        transaction = connection.begin()
        try:
            connection.execute(text("SELECT set_config('search_path', '', true)"))
            search = connection.execute(
                text("""
                    INSERT INTO public.foods
                        (id, name_ar, source, source_id, calories, protein, carbs, fat)
                    VALUES (:id, 'مقلوبة', 'regional', :source_id, 100, 1, 2, 3)
                    RETURNING search
                """),
                {"id": uuid7(), "source_id": str(uuid7())},
            ).scalar_one()
            assert search == "مقلوبه"
        finally:
            transaction.rollback()
    engine.dispose()


def test_arabic_trigrams_are_available():
    engine = create_engine(Settings().database_url.get_secret_value())
    with engine.connect() as connection:
        trigrams = connection.execute(text("SELECT show_trgm('مقلوبه')")).scalar_one()
    engine.dispose()

    assert trigrams


def test_visible_foods_include_catalog_and_only_the_users_own(
    client, auth_headers, food_rows
):
    alice_headers = auth_headers()
    bob_headers = auth_headers()
    alice_id = client.get("/me", headers=alice_headers).json()["id"]
    bob_id = client.get("/me", headers=bob_headers).json()["id"]
    catalog = food_rows("تفاح")
    own = food_rows("موز", owner_id=alice_id)
    food_rows("كعك", owner_id=bob_id)

    async def read():
        async with client.app_state["sessions"]() as session:
            return [
                str(row.id)
                for row in (await session.scalars(visible_foods(alice_id))).all()
            ]

    assert set(client.portal.call(read)) == {catalog, own}


def test_food_search_requires_sign_in_and_returns_rounded_food(
    client, auth_headers, food_rows
):
    food_id = food_rows(
        "مقلوبة", "Maqluba", calories=100.25, protein=1.25, carbs=2.24, fat=3.35
    )

    assert client.get("/foods", params={"q": "مقلو"}).status_code == 401
    response = client.get("/foods", params={"q": "مقلو"}, headers=auth_headers())

    assert response.status_code == 200
    assert response.json() == [
        {
            "id": food_id,
            "name_ar": "مقلوبة",
            "name_en": "Maqluba",
            "calories": 100.3,
            "protein": 1.3,
            "carbs": 2.2,
            "fat": 3.4,
        }
    ]


@pytest.mark.parametrize(
    ("stored", "typed"),
    [
        ("مقلوبة", "مقلوبه"),
        ("أرز", "ارز"),
        ("Maqluba", "maqluba"),
        ("قطايف", "قطائف"),
        ("بیض", "بيض"),
        ("کنافه", "كنافة"),
        ("٧ اب", "7 أب"),
        ("Crème caramel", "creme"),
        ("ﻣﻘﻠﻮﺑﺔ", "مقلوبة"),
        ("أرز", "أرز"),
    ],
)
def test_search_cleans_arabic_and_latin_equivalents(
    client, auth_headers, food_rows, stored, typed
):
    food_id = food_rows(stored)

    response = client.get("/foods", params={"q": typed}, headers=auth_headers())

    assert response.status_code == 200
    assert [food["id"] for food in response.json()] == [food_id]


@pytest.mark.parametrize(
    ("stored_ar", "stored_en", "typed"),
    [
        ("مقلوبة", "Maqluba", "مقلو"),
        ("شاورما", "Chicken shawarma", "shaw"),
        ("صدر دجاج مشوي", "Grilled chicken breast", "دجاج"),
        ("شاورما دجاج", "Chicken shawarma", "shawerma"),
        ("شاورما", "Chicken shawarma", "شاورما"),
        ("شاورما", "Chicken shawarma", "chicken"),
    ],
)
def test_search_finds_partial_words_typos_and_both_languages(
    client, auth_headers, food_rows, stored_ar, stored_en, typed
):
    food_id = food_rows(stored_ar, stored_en)

    response = client.get("/foods", params={"q": typed}, headers=auth_headers())

    assert response.status_code == 200
    assert [food["id"] for food in response.json()] == [food_id]


def test_search_ranks_own_then_name_starts_then_contains(
    client, auth_headers, food_rows
):
    headers = auth_headers()
    user_id = client.get("/me", headers=headers).json()["id"]
    contains = food_rows("صدر دجاج مشوي")
    starts = food_rows("دجاج مشوي")
    own = food_rows("صدر دجاج خاص", owner_id=user_id)

    response = client.get("/foods", params={"q": "دجاج"}, headers=headers)

    assert response.status_code == 200
    assert [food["id"] for food in response.json()] == [own, starts, contains]


def test_search_ranks_an_other_name_start_before_a_contains_match(
    client, auth_headers, food_rows
):
    contains = food_rows("صدر دجاج مشوي")
    alias_starts = food_rows("وجبة مشوية", other_names=["دجاج بلدي"])

    response = client.get("/foods", params={"q": "دجاج"}, headers=auth_headers())

    assert response.status_code == 200
    assert [food["id"] for food in response.json()] == [alias_starts, contains]


def test_search_returns_at_most_twenty_results(client, auth_headers, food_rows):
    ids = [food_rows(f"اختبار خاص {number}") for number in range(21)]

    response = client.get("/foods", params={"q": "اختبار"}, headers=auth_headers())

    assert response.status_code == 200
    assert len(response.json()) == 20
    assert {food["id"] for food in response.json()}.issubset(set(ids))


def test_search_keeps_other_trainees_food_private(client, auth_headers, food_rows):
    alice = auth_headers()
    bob = auth_headers()
    alice_id = client.get("/me", headers=alice).json()["id"]
    bob_id = client.get("/me", headers=bob).json()["id"]
    own = food_rows("طعام خاص", owner_id=alice_id)
    food_rows("طعام خاص جدا", owner_id=bob_id)

    response = client.get("/foods", params={"q": "طعام"}, headers=alice)

    assert response.status_code == 200
    assert [food["id"] for food in response.json()] == [own]


@pytest.mark.parametrize("symbol", ["%", "_", "\\"])
def test_search_treats_like_wildcards_literally(
    client, auth_headers, food_rows, symbol
):
    matching = food_rows(f"خليط {symbol} خاص")
    food_rows("خليط عادي")

    response = client.get("/foods", params={"q": symbol}, headers=auth_headers())

    assert response.status_code == 200
    assert [food["id"] for food in response.json()] == [matching]


@pytest.mark.parametrize("query", [None, "", "x" * 101, "a\x00b"])
def test_search_requires_one_to_one_hundred_characters(client, auth_headers, query):
    response = client.get(
        "/foods",
        params={"q": query} if query is not None else {},
        headers=auth_headers(),
    )

    assert response.status_code == 422


def test_search_with_only_diacritics_returns_no_foods(client, auth_headers, food_rows):
    food_rows("مقلوبة")

    response = client.get("/foods", params={"q": "َُ"}, headers=auth_headers())

    assert response.status_code == 200
    assert response.json() == []
