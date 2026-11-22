class FoodNotVisible(Exception):
    """The requested food is not visible to the trainee."""


class EntryOfAnotherUser(Exception):
    """The entry ID belongs to another trainee."""


class EntryWriteFailed(Exception):
    """The database rejected a diary entry write."""
