"""Daily calorie and macro targets, calculated from a user's profile.

Targets are calculated on every request and never stored. The rules come from
#8; see decision 15 in docs/decisions.md.

For other modules:
    calculate_targets: turns sex, age, weight, height, activity level and goal
        into daily calories, protein, fat and carbs (whole numbers), plus
        maintenance calories and whether the calorie minimum was applied.
        No database or date inside: the caller passes the age.

For wiring the app (main.py):
    router: GET /me/targets, the signed-in user's targets from their saved
        profile, or 404 if they have none.
"""

from ghbot.targets.calculation import calculate_targets
from ghbot.targets.router import router

__all__ = ["calculate_targets", "router"]
