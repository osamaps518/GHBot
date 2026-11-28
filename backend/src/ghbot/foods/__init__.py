"""Catalog and owned foods stored in one table.

For other modules:
    Food: the persisted food row.
    changed_foods: visible foods for a pull, rounded like search: those a
        trainee's used-food IDs select that changed since a marker, and
        those of the pulled entries, changed or not.
    visible_foods: select the catalog and a trainee's own foods.

For wiring the app (main.py):
    router:
        GET /foods?q=: up to 20 catalog and own foods whose Arabic or English
            name matches q, own foods first.
"""

from ghbot.foods.application import changed_foods, visible_foods
from ghbot.foods.models import Food
from ghbot.foods.router import router

__all__ = ["Food", "changed_foods", "router", "visible_foods"]
