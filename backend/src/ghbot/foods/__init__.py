"""Catalog and owned foods stored in one table.

For other modules:
    Calories, Macro: the per-100 g value types, 0–900 and 0–100 with one
        decimal (decision 38); a diary entry uses the same ones, so every
        own food can be logged.
    Food: the persisted food row.
    FoodResponse: a food as the API sends it.
    changed_foods: visible foods for a pull, rounded like search: the
        trainee's own foods and used foods that changed since a marker, and
        those of the pulled entries, changed or not.
    visible_foods: select the catalog and a trainee's own foods.

For wiring the app (main.py):
    router:
        GET /foods?q=: up to 20 catalog and own foods whose Arabic or English
            name matches q, own foods first.
        PUT /me/foods/{id}: save the caller's own food if its revision is
            newer, else return the stored one; 409 if the id is a catalog food
            or another trainee's.
"""

from ghbot.foods.application import changed_foods, visible_foods
from ghbot.foods.models import Food
from ghbot.foods.router import router
from ghbot.foods.schemas import Calories, FoodResponse, Macro

__all__ = [
    "Calories",
    "Food",
    "FoodResponse",
    "Macro",
    "changed_foods",
    "router",
    "visible_foods",
]
