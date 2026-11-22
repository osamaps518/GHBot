# Catalog food seed files

Add reviewed CSV files here, one per source: `usda.csv`,
`open_food_facts.csv`, or `regional.csv`. Do not add `trainee.csv`.

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

## open_food_facts.csv

Contains data from Open Food Facts (https://world.openfoodfacts.org), available
under the Open Database License
(https://opendatacommons.org/licenses/odbl/1-0/). Its individual contents are
available under the Database Contents License
(https://opendatacommons.org/licenses/dbcl/1-0/). The repository's MIT license
does not cover this file. Exported on 2026-11-22. The export came with no other
notice.

The file holds only Open Food Facts rows, with no values from another source.
Fix a product here, in this file, never in the database.

Made with the API v2 search, `languages_tags=en:arabic`, for Palestine, Jordan,
Lebanon, Saudi Arabia, the UAE and Egypt. Kept: Arabic letters in
`product_name_ar`; calories, protein, carbs and fat all present; calories ≤ 900,
each macro ≤ 100, their sum ≤ 105; calories within 25% or 20 kcal of 4P + 4C +
9F; an unused 8, 12 or 13 digit barcode. Brands are `other_names`; `serving`
only when given in grams.
