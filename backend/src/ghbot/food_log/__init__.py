"""Diary entries stored for a trainee.

It uses `foods` to check that a logged food is visible to the trainee and to get
the changed foods for a pull, passing its query of the trainee's used food IDs.
It doesn't use `targets`.

For other modules:
    FoodLogEntry: the persisted diary row.

For wiring the app (main.py):
    router:
        GET /me/food-log/changes: return the caller's changed entries and used
            foods since an optional marker, plus the next overlapping marker.
            The foods of the returned entries come too, changed or not. The
            marker, `since`, is a time-zone-aware timestamp, such as ISO 8601.
        PUT /me/food-log/entries/{id}: save the entry if its revision is newer,
            else return the stored one; 409 if another trainee owns the id.
        DELETE /me/food-log/entries/{id}: mark the entry deleted for good, even
            before it is saved; 409 if another trainee owns the id.
"""

from ghbot.food_log.models import FoodLogEntry
from ghbot.food_log.router import router

__all__ = ["FoodLogEntry", "router"]
