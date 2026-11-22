from uuid import uuid7

import pytest
from sqlalchemy import create_engine, text

from ghbot.config import Settings


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


def test_arabic_trigrams_are_available():
    engine = create_engine(Settings().database_url.get_secret_value())
    with engine.connect() as connection:
        trigrams = connection.execute(
            text("SELECT show_trgm('مقلوبه')")
        ).scalar_one()
    engine.dispose()

    assert trigrams
