"""Catalog and owned foods stored in one table.

For other modules:
    Food: the persisted food row.
    visible_foods: select the catalog and a trainee's own foods.
"""

from ghbot.foods.application import visible_foods
from ghbot.foods.models import Food

__all__ = ["Food", "visible_foods"]
