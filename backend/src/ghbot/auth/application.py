from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from ghbot.auth.models import User


@dataclass(frozen=True)
class SignedInUser:
    id: UUID
    created_at: datetime


async def find_or_create_user(session: AsyncSession, subject: str) -> SignedInUser:
    """Return the user for this subject, creating it on first sign-in.

    Concurrent first requests share the row: `auth_subject` is unique, and the
    insert does nothing on a conflict, so each request then reads the one row.
    """
    query = select(User.id, User.created_at).where(User.auth_subject == subject)
    user = (await session.execute(query)).one_or_none()
    if user is None:
        await session.execute(
            insert(User)
            .values(auth_subject=subject)
            .on_conflict_do_nothing(index_elements=[User.auth_subject])
        )
        user = (await session.execute(query)).one()
        await session.commit()
    return SignedInUser(id=user.id, created_at=user.created_at)
