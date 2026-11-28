"""Token authentication and local user identities.

For routes in other modules:
    CurrentUser: route parameter that gives the signed-in user as a plain frozen
        value with our user id and when the account was created, or answers
        401.
    User: our users table. Other tables reference its id.

For wiring the app (main.py):
    DevAuthProvider: issues and verifies local development tokens.
    router:
        GET /me: our user id for the signed-in user, and when the account was
            created.
    create_dev_router:
        POST /dev/token: a signed token for the given subject, for development only.
"""

from ghbot.auth.dependencies import CurrentUser
from ghbot.auth.models import User
from ghbot.auth.provider import DevAuthProvider
from ghbot.auth.router import create_dev_router, router

__all__ = ["CurrentUser", "DevAuthProvider", "User", "create_dev_router", "router"]
