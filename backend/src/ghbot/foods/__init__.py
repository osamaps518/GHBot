"""Catalog and owned foods stored in one table.

For other modules:
    Food: the persisted food row.
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

__all__ = ["Food", "changed_foods", "router", "visible_foods"]
