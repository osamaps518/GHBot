"""Diary entries stored for a trainee.

For other modules:
    FoodLogEntry: the persisted diary row.
    router: PUT and DELETE for the signed-in trainee's entries.
"""

from ghbot.food_log.models import FoodLogEntry
from ghbot.food_log.router import router

__all__ = ["FoodLogEntry", "router"]
