"""Load curated catalog CSV files into the foods table."""

import argparse
import asyncio
import csv
import math
from itertools import groupby
from pathlib import Path

from sqlalchemy import func, or_
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import create_async_engine

from ghbot.config import Settings
from ghbot.foods.models import Food

SOURCES = frozenset({"usda", "open_food_facts", "regional"})
UNIT_CODES = frozenset({"piece", "slice", "cup", "tablespoon", "teaspoon", "serving"})
COLUMNS = (
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
)
UPDATED_COLUMNS = tuple(name for name in COLUMNS if name != "source_id")
DEFAULT_FOLDER = Path(__file__).resolve().parents[3] / "seed"


def _number(value: str, label: str) -> float:
    try:
        number = float(value)
    except ValueError as exc:
        raise ValueError(f"{label} must be a finite nonnegative number") from exc
    if not math.isfinite(number) or number < 0:
        raise ValueError(f"{label} must be a finite nonnegative number")
    return number


def _row(row: dict[str, str], source: str) -> dict[str, object]:
    if not row["source_id"].strip():
        raise ValueError("source_id is required")
    if not row["name_ar"].strip():
        raise ValueError("Arabic name is required")
    units: dict[str, float] = {}
    if row["units"].strip():
        for part in row["units"].split("|"):
            code, separator, amount = part.partition("=")
            code = code.strip()
            if code not in UNIT_CODES:
                raise ValueError(f"unknown unit code: {code}")
            if not separator or code in units:
                raise ValueError(f"invalid unit: {part}")
            units[code] = _number(amount, f"unit {code}")
    return {
        "source": source,
        "source_id": row["source_id"].strip(),
        "name_ar": row["name_ar"].strip(),
        "name_en": row["name_en"].strip() or None,
        "other_names": [
            name.strip() for name in row["other_names"].split("|") if name.strip()
        ],
        "calories": _number(row["calories"], "calories"),
        "protein": _number(row["protein"], "protein"),
        "carbs": _number(row["carbs"], "carbs"),
        "fat": _number(row["fat"], "fat"),
        "units": units,
        "density": _number(row["density"], "density")
        if row["density"].strip()
        else None,
        "barcode": row["barcode"].strip() or None,
    }


def read_rows(folder: Path) -> list[dict[str, object]]:
    if not folder.is_dir():
        raise ValueError(f"{folder}: no such folder")
    rows: list[dict[str, object]] = []
    barcodes: dict[str, str] = {}
    for path in sorted(folder.glob("*.csv")):
        source = path.stem
        if source not in SOURCES:
            raise ValueError(f"{path.name}: unknown seed source")
        seen: set[str] = set()
        try:
            with path.open(newline="", encoding="utf-8-sig") as file:
                reader = csv.DictReader(file)
                if reader.fieldnames != list(COLUMNS):
                    raise ValueError(f"{path.name}:1: expected seed columns")
                for raw in reader:
                    line = reader.line_num
                    try:
                        if None in raw or any(value is None for value in raw.values()):
                            raise ValueError("incorrect number of columns")
                        row = _row(raw, source)
                        source_id = str(row["source_id"])
                        if source_id in seen:
                            raise ValueError(f"duplicate source_id: {source_id}")
                        barcode = row["barcode"]
                        if isinstance(barcode, str):
                            if barcode in barcodes:
                                raise ValueError(
                                    f"duplicate barcode: {barcode} (also {barcodes[barcode]})"
                                )
                            barcodes[barcode] = f"{path.name}:{line}"
                        seen.add(source_id)
                        rows.append(row)
                    except ValueError as exc:
                        raise ValueError(f"{path.name}:{line}: {exc}") from exc
        except UnicodeDecodeError as exc:
            raise ValueError(f"{path.name}: not UTF-8 ({exc.reason})") from exc
    return rows


async def load(folder: Path = DEFAULT_FOLDER) -> None:
    rows = read_rows(folder)
    if not rows:
        return
    engine = create_async_engine(Settings().database_url.get_secret_value())
    table = Food.__table__
    statement = insert(Food)
    excluded = statement.excluded
    statement = statement.on_conflict_do_update(
        index_elements=[table.c.source, table.c.source_id],
        index_where=table.c.owner_id.is_(None),
        set_={
            **{name: getattr(excluded, name) for name in UPDATED_COLUMNS},
            "updated_at": func.clock_timestamp(),
        },
        where=or_(
            *(
                getattr(table.c, name).is_distinct_from(getattr(excluded, name))
                for name in UPDATED_COLUMNS
            )
        ),
    )
    try:
        for _, grouped in groupby(rows, key=lambda row: row["source"]):
            async with engine.begin() as connection:
                await connection.execute(statement, list(grouped))
    finally:
        await engine.dispose()


def main() -> None:
    parser = argparse.ArgumentParser(description="Load catalog foods from CSV files")
    parser.add_argument("folder", nargs="?", type=Path, default=DEFAULT_FOLDER)
    args = parser.parse_args()
    try:
        asyncio.run(load(args.folder))
    except ValueError as exc:
        parser.exit(1, f"{exc}\n")


if __name__ == "__main__":
    main()
