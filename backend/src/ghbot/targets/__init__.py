"""Recommended targets from a profile and a trainee's optional custom targets.

Recommended targets are recalculated on every request. Custom values and their
edit history are stored; see decisions 15 and 37 in docs/decisions.md.

For other modules:
    calculate_targets: turns a saved profile value into daily calories, protein,
        fat and carbs (whole numbers), plus maintenance calories and flags.
    CustomTargets, TargetHistory: the saved custom row and its edit history.

For wiring the app (main.py):
    router:
        GET /me/targets: the signed-in user's targets from their saved profile,
            or 404 if they have none.
        PUT /me/targets/custom: save custom values and return effective targets.
        DELETE /me/targets/custom: reset to recommended targets.
"""

from ghbot.targets.application import calculate_targets
from ghbot.targets.models import CustomTargets, TargetHistory
from ghbot.targets.router import router

__all__ = ["CustomTargets", "TargetHistory", "calculate_targets", "router"]
