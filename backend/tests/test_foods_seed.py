import csv
import asyncio
import sys
from pathlib import Path
from uuid import uuid7

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.exc import IntegrityError

from ghbot.config import Settings
from ghbot.foods.seed import load, main


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


def test_database_requires_names_and_unique_catalog_source_id(db):
    user_id = uuid7()
    db.execute(
        text("INSERT INTO users (id, auth_subject) VALUES (:id, :subject)"),
        {"id": user_id, "subject": str(user_id)},
    )
    base = {
        "id": uuid7(),
        "name_ar": "تفاح",
        "source": "regional",
        "source_id": str(uuid7()),
        "calories": 50,
        "protein": 0,
        "carbs": 12,
        "fat": 0,
    }
    insert = text("""
        INSERT INTO foods (id, name_ar, source, source_id, calories, protein, carbs, fat)
        VALUES (:id, :name_ar, :source, :source_id, :calories, :protein, :carbs, :fat)
    """)
    db.execute(insert, base)
    for invalid in (
        {**base, "id": uuid7(), "name_ar": None, "source_id": str(uuid7())},
        {**base, "id": uuid7()},
    ):
        savepoint = db.begin_nested()
        with pytest.raises(IntegrityError):
            db.execute(insert, invalid)
        savepoint.rollback()

    savepoint = db.begin_nested()
    with pytest.raises(IntegrityError):
        db.execute(
            text("""
                INSERT INTO foods (id, source, owner_id, calories, protein, carbs, fat)
                VALUES (:id, 'trainee', :owner_id, 50, 0, 12, 0)
            """),
            {"id": uuid7(), "owner_id": user_id},
        )
    savepoint.rollback()


CSV_COLUMNS = [
    "source_id",
    "name_ar",
    "name_en",
    "other_names",
    "calories",
    "protein",
    "carbs",
    "fat",
    "units",
    "density",
    "barcode",
]


def write_csv(folder: Path, source: str, rows: list[dict[str, str]]) -> None:
    with (folder / f"{source}.csv").open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=CSV_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)


def seed(folder: Path) -> None:
    asyncio.run(load(folder))


def test_seed_is_idempotent_and_updates_only_changed_catalog_row(tmp_path):
    engine = create_engine(Settings().database_url.get_secret_value())
    first_id, second_id, owner_id, owned_id = (uuid7() for _ in range(4))
    first = {
        "source_id": str(first_id),
        "name_ar": "تفاح",
        "name_en": "Apple",
        "other_names": "تفاح أحمر|Red apple",
        "calories": "50",
        "protein": "0.3",
        "carbs": "12",
        "fat": "0.2",
        "units": "cup=240|piece=50",
        "density": "0.8",
        "barcode": "000000123",
    }
    second = {
        **first,
        "source_id": str(second_id),
        "name_ar": "موز",
        "barcode": "000000124",
    }
    try:
        with engine.begin() as connection:
            connection.execute(
                text("INSERT INTO users (id, auth_subject) VALUES (:id, :subject)"),
                {"id": owner_id, "subject": str(owner_id)},
            )
            connection.execute(
                text("""
                INSERT INTO foods (id, name_en, calories, protein, carbs, fat,
                                   source, owner_id, barcode)
                VALUES (:id, 'Mine', 1, 1, 1, 1, 'trainee', :owner_id, '000000123')
            """),
                {"id": owned_id, "owner_id": owner_id},
            )
        write_csv(tmp_path, "usda", [first, second])
        seed(tmp_path)
        with engine.connect() as connection:
            original = (
                connection.execute(
                    text("""
                SELECT source_id, calories, updated_at, other_names, units, density
                FROM foods WHERE source = 'usda' AND source_id IN (:first, :second)
            """),
                    {"first": str(first_id), "second": str(second_id)},
                )
                .mappings()
                .all()
            )
            owned_before = connection.execute(
                text("SELECT updated_at FROM foods WHERE id = :id"),
                {"id": owned_id},
            ).scalar_one()
        assert len(original) == 2
        assert {row["source_id"]: row["calories"] for row in original} == {
            str(first_id): 50,
            str(second_id): 50,
        }
        assert original[0]["other_names"] == ["تفاح أحمر", "Red apple"]
        assert original[0]["units"] == {"cup": 240, "piece": 50}
        assert original[0]["density"] == 0.8
        seed(tmp_path)
        with engine.connect() as connection:
            unchanged = (
                connection.execute(
                    text("""
                SELECT source_id, updated_at FROM foods
                WHERE source = 'usda' AND source_id IN (:first, :second)
            """),
                    {"first": str(first_id), "second": str(second_id)},
                )
                .mappings()
                .all()
            )
        assert {row["source_id"]: row["updated_at"] for row in unchanged} == {
            row["source_id"]: row["updated_at"] for row in original
        }
        write_csv(tmp_path, "usda", [{**first, "calories": "55"}, second])
        seed(tmp_path)
        with engine.connect() as connection:
            current = (
                connection.execute(
                    text("""
                SELECT source_id, calories, updated_at FROM foods
                WHERE source = 'usda' AND source_id IN (:first, :second)
            """),
                    {"first": str(first_id), "second": str(second_id)},
                )
                .mappings()
                .all()
            )
            owned = connection.execute(
                text("SELECT name_en, calories, updated_at FROM foods WHERE id = :id"),
                {"id": owned_id},
            ).one()
        before = {row["source_id"]: row for row in original}
        after = {row["source_id"]: row for row in current}
        assert after[str(first_id)]["calories"] == 55
        assert after[str(first_id)]["updated_at"] > before[str(first_id)]["updated_at"]
        assert (
            after[str(second_id)]["updated_at"] == before[str(second_id)]["updated_at"]
        )
        assert owned == ("Mine", 1, owned_before)
        write_csv(tmp_path, "usda", [{**first, "calories": "55"}])
        seed(tmp_path)
        with engine.connect() as connection:
            assert (
                connection.execute(
                    text(
                        "SELECT count(*) FROM foods WHERE source = 'usda' AND source_id = :id"
                    ),
                    {"id": str(second_id)},
                ).scalar_one()
                == 1
            )
    finally:
        with engine.begin() as connection:
            connection.execute(
                text(
                    "DELETE FROM foods WHERE id = :id OR (source = 'usda' AND source_id IN (:first, :second))"
                ),
                {"id": owned_id, "first": str(first_id), "second": str(second_id)},
            )
            connection.execute(
                text("DELETE FROM users WHERE id = :id"), {"id": owner_id}
            )
        engine.dispose()


@pytest.mark.parametrize(
    ("bad_change", "expected"),
    [
        ({"units": "bowl=200"}, "unknown unit code"),
        ({"name_ar": ""}, "Arabic name is required"),
        ({"calories": "NaN"}, "finite nonnegative number"),
        ({"calories": "-1"}, "finite nonnegative number"),
        ({"density": "Infinity"}, "finite nonnegative number"),
    ],
)
def test_refused_row_names_file_and_line_and_writes_nothing(
    tmp_path, bad_change, expected
):
    valid_id, bad_id = str(uuid7()), str(uuid7())
    valid = {
        "source_id": valid_id,
        "name_ar": "تفاح",
        "name_en": "Apple",
        "other_names": "",
        "calories": "50",
        "protein": "0",
        "carbs": "12",
        "fat": "0",
        "units": "",
        "density": "",
        "barcode": "",
    }
    write_csv(tmp_path, "regional", [valid])
    write_csv(tmp_path, "usda", [{**valid, "source_id": bad_id, **bad_change}])

    with pytest.raises(ValueError) as error:
        seed(tmp_path)
    assert "usda.csv:2:" in str(error.value)
    assert expected in str(error.value)
    engine = create_engine(Settings().database_url.get_secret_value())
    try:
        with engine.connect() as connection:
            count = connection.execute(
                text("SELECT count(*) FROM foods WHERE source_id = :id"),
                {"id": valid_id},
            ).scalar_one()
        assert count == 0
    finally:
        engine.dispose()


def test_duplicate_source_id_in_file_is_refused_at_second_row(tmp_path):
    row = {
        "source_id": str(uuid7()),
        "name_ar": "تفاح",
        "name_en": "",
        "other_names": "",
        "calories": "50",
        "protein": "0",
        "carbs": "12",
        "fat": "0",
        "units": "",
        "density": "",
        "barcode": "",
    }
    write_csv(tmp_path, "usda", [row, row])

    with pytest.raises(ValueError, match="usda.csv:3: duplicate source_id"):
        seed(tmp_path)


@pytest.mark.parametrize("across_files", [False, True])
def test_duplicate_barcode_reports_second_file_and_line(tmp_path, across_files):
    first_id, second_id = str(uuid7()), str(uuid7())
    row = {
        "source_id": first_id,
        "name_ar": "تفاح",
        "name_en": "",
        "other_names": "",
        "calories": "50",
        "protein": "0",
        "carbs": "12",
        "fat": "0",
        "units": "",
        "density": "",
        "barcode": "000123",
    }
    second = {**row, "source_id": second_id}
    if across_files:
        write_csv(tmp_path, "regional", [row])
        write_csv(tmp_path, "usda", [second])
        expected_line = 2
    else:
        write_csv(tmp_path, "usda", [row, second])
        expected_line = 3

    with pytest.raises(ValueError, match=f"usda.csv:{expected_line}: duplicate barcode"):
        seed(tmp_path)

    engine = create_engine(Settings().database_url.get_secret_value())
    try:
        with engine.connect() as connection:
            assert connection.execute(
                text("SELECT count(*) FROM foods WHERE source_id IN (:first, :second)"),
                {"first": first_id, "second": second_id},
            ).scalar_one() == 0
    finally:
        engine.dispose()


def test_non_utf8_csv_reports_file_name(tmp_path):
    row = {
        "source_id": str(uuid7()),
        "name_ar": "تفاح",
        "name_en": "Apple",
        "other_names": "",
        "calories": "50",
        "protein": "0",
        "carbs": "12",
        "fat": "0",
        "units": "",
        "density": "",
        "barcode": "",
    }
    with (tmp_path / "usda.csv").open("w", newline="", encoding="cp1256") as file:
        writer = csv.DictWriter(file, fieldnames=CSV_COLUMNS)
        writer.writeheader()
        writer.writerow(row)

    with pytest.raises(ValueError, match="usda.csv: not UTF-8"):
        seed(tmp_path)


def test_missing_seed_folder_exits_nonzero_and_writes_nothing(
    tmp_path, monkeypatch, capsys
):
    missing = tmp_path / "missing"
    engine = create_engine(Settings().database_url.get_secret_value())
    try:
        with engine.connect() as connection:
            before = connection.execute(text("SELECT count(*) FROM foods")).scalar_one()
        monkeypatch.setattr(sys, "argv", ["seed", str(missing)])
        with pytest.raises(SystemExit) as error:
            main()
        assert error.value.code != 0
        assert f"{missing}: no such folder" in capsys.readouterr().err
        with engine.connect() as connection:
            after = connection.execute(text("SELECT count(*) FROM foods")).scalar_one()
        assert after == before
    finally:
        engine.dispose()


def test_existing_empty_seed_folder_loads_nothing(tmp_path):
    seed(tmp_path)


@pytest.mark.parametrize("source", ["trainee", "mystery"])
def test_non_catalog_csv_is_refused(tmp_path, source):
    write_csv(tmp_path, source, [])

    with pytest.raises(ValueError, match=f"{source}.csv: unknown seed source"):
        seed(tmp_path)
