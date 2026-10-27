"""Public targets API: calculate_targets for rules, router for GET /me/targets."""

from ghbot.targets.calculation import calculate_targets
from ghbot.targets.router import router

__all__ = ["calculate_targets", "router"]
