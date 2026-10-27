"""Saved onboarding profiles: one per user, with the details targets are based on.

For other modules:
    Profile: our profiles table, one row per user, keyed by the user's id.
        Holds birth year and month, sex, height, weight, activity level and goal.
    age_on_date: a user's age in whole years on a given date. The birthday
        counts as the last day of the birth month, since we don't store the day.
    utc_today: route parameter that gives today's date in UTC. Tests override
        it to fix the date.

For wiring the app (main.py):
    router: GET and PUT /me/profile.
"""

from ghbot.profiles.models import Profile
from ghbot.profiles.router import age_on_date, router, utc_today

__all__ = ["Profile", "age_on_date", "router", "utc_today"]
