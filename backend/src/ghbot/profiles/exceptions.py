class ProfileNotFound(Exception):
    """The signed-in user has no saved profile."""


class AgeOutOfRange(ValueError):
    def __init__(self, birth_year: int) -> None:
        self.birth_year = birth_year
