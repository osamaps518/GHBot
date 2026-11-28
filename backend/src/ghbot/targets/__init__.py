"""Recommended targets from a profile and a trainee's optional custom targets.

Recommended targets are recalculated on every request. Custom values and their
edit history are stored (decisions 15 and 37).

For other modules:
    calculate_targets: turns a saved profile value into daily calories, protein,
        fat and carbs (whole numbers), plus maintenance calories and flags.
    CustomTargets, TargetHistory: the saved custom row and its edit history.

For wiring the app (main.py):
    router:
        GET /me/targets: the signed-in user's targets in effect (custom or
            recommended) plus the recommended ones, or 404 if they have no
            saved profile.
        PUT /me/targets/custom: save custom values and return effective targets;
            422 `below_minimum`, with the minimum in `ctx`, or `macros_mismatch`.
        DELETE /me/targets/custom: reset to recommended targets.
"""

from ghbot.targets.application import calculate_targets
from ghbot.targets.models import CustomTargets, TargetHistory
from ghbot.targets.router import router

__all__ = ["CustomTargets", "TargetHistory", "calculate_targets", "router"]
