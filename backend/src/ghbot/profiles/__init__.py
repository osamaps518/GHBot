"""Saved onboarding profiles.

For app wiring, router provides GET and PUT /me/profile.
"""

from ghbot.profiles.router import router

__all__ = ["router"]
