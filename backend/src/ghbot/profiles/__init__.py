"""Saved onboarding profiles: one per user, with the details targets are based on.

For other modules:
    SavedProfile: route parameter providing the caller's saved profile and age.
    ProfileSnapshot: plain frozen value carrying that profile to other modules.
    Sex, ActivityLevel, Goal: accepted profile codes.
    utc_today: dependency that gives today's date in UTC. Tests override it.

For wiring the app (main.py):
    router: GET and PUT /me/profile.
"""

from ghbot.profiles.application import ProfileSnapshot
from ghbot.profiles.dependencies import SavedProfile, utc_today
from ghbot.profiles.models import ActivityLevel, Goal, Profile, Sex
from ghbot.profiles.router import router

__all__ = [
    "ActivityLevel",
    "Goal",
    "Profile",
    "ProfileSnapshot",
    "SavedProfile",
    "Sex",
    "router",
    "utc_today",
]
