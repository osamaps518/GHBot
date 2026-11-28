class BelowMinimum(ValueError):
    """Custom calories are below the profile's daily minimum."""


class MacrosMismatch(ValueError):
    """Macro energy differs from the chosen calories by at least 100."""
