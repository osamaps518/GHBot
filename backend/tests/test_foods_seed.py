from uuid import uuid7

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.exc import IntegrityError

from ghbot.config import Settings


@pytest.fixture
def db():
    url = Settings().database_url.get_secret_value()
    engine = create_engine(url)
    with engine.connect() as connection:
        transaction = connection.begin()
        yield connection
        transaction.rollback()
    engine.dispose()


def test_database_refuses_invalid_ownership_and_duplicate_catalog_barcode(db):
    user_id = uuid7()
    db.execute(
        text("INSERT INTO users (id, auth_subject) VALUES (:id, :subject)"),
        {"id": user_id, "subject": str(user_id)},
    )
    base = {
        "id": uuid7(),
        "name_ar": "تفاح",
        "source": "usda",
        "source_id": str(uuid7()),
        "owner_id": None,
        "barcode": "000123",
        "calories": 50,
        "protein": 0,
        "carbs": 12,
        "fat": 0,
    }
    insert = text("""
        INSERT INTO foods (id, name_ar, source, source_id, owner_id, barcode,
                           calories, protein, carbs, fat)
        VALUES (:id, :name_ar, :source, :source_id, :owner_id, :barcode,
                :calories, :protein, :carbs, :fat)
    """)
    for invalid in (
        {**base, "id": uuid7(), "source": "trainee", "source_id": None},
        {**base, "id": uuid7(), "owner_id": user_id},
    ):
        savepoint = db.begin_nested()
        with pytest.raises(IntegrityError):
            db.execute(insert, invalid)
        savepoint.rollback()

    db.execute(insert, base)
    savepoint = db.begin_nested()
    with pytest.raises(IntegrityError):
        db.execute(insert, {**base, "id": uuid7(), "source_id": str(uuid7())})
    savepoint.rollback()
