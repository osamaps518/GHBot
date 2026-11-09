from dataclasses import dataclass
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from ghbot.auth.models import User


@dataclass(frozen=True)
class SignedInUser:
    id: UUID


async def find_or_create_user(session: AsyncSession, subject: str) -> SignedInUser:
    query = select(User.id).where(User.auth_subject == subject)
    user_id = await session.scalar(query)
    if user_id is None:
        # Concurrent first requests share the row through the unique constraint.
        await session.execute(
            insert(User)
            .values(auth_subject=subject)
            .on_conflict_do_nothing(index_elements=[User.auth_subject])
        )
        user_id = (await session.scalars(query)).one()
        await session.commit()
    return SignedInUser(id=user_id)
