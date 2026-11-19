# Catalog food seed files

Add reviewed CSV files here, one per source: `usda.csv`,
`open_food_facts.csv`, or `regional.csv`. Do not add `trainee.csv`. This folder
has no food data yet.

Use this header, in order:

```csv
source_id,name_ar,name_en,other_names,calories,protein,carbs,fat,units,density,barcode
```

`source_id` is the source's stable row ID: a USDA FDC ID, an Open Food Facts
code, or our slug for a regional dish. `name_ar` is required. `name_en`,
`other_names`, `units`, `density`, and `barcode` may be empty. `barcode` is text,
so keep leading zeros. `other_names` separates names with `|`.

Nutrition numbers are per 100 g. `calories`, `protein`, `carbs`, and `fat` are
required nonnegative finite numbers; `density`, when present, is grams per ml.
`units` maps a code to grams using `|`, for example `cup=240|piece=50`.
Accepted codes are `piece`, `slice`, `cup`, `tablespoon`, `teaspoon`, and
`serving`. Unit weights must also be nonnegative finite numbers. Empty cells
mean no value or, for lists and maps, an empty collection.

Run `uv run python -m ghbot.foods.seed` from `backend/` after a CSV change.
The command refuses invalid rows with their file and line number, writes all
files in one transaction, updates changed catalog rows, and leaves removed
rows in the table. CSV changes should be reviewed in a pull request.
