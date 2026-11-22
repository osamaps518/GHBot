"""Diary entries stored for a trainee.

For other modules:
    FoodLogEntry: the persisted diary row.

For wiring the app (main.py):
    router:
        PUT /me/food-log/entries/{id}: save the entry if its revision is newer,
            else return the stored one; 409 if another trainee owns the id.
        DELETE /me/food-log/entries/{id}: mark the entry deleted for good, even
            before it is saved; 409 if another trainee owns the id.
"""

from ghbot.food_log.models import FoodLogEntry
from ghbot.food_log.router import router

__all__ = ["FoodLogEntry", "router"]
