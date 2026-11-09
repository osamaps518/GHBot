class ProfileNotFound(Exception):
    """The signed-in user has no saved profile."""


class AgeOutOfRange(ValueError):
    """The age on today's date is outside 18 to 100."""
