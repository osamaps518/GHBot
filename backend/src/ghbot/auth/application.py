from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from ghbot.auth.models import User


async def find_or_create_user(session: AsyncSession, subject: str) -> User:
    query = select(User).where(User.auth_subject == subject)
    user = await session.scalar(query)
    if user is None:
        # Concurrent first requests share the row through the unique constraint.
        await session.execute(
            insert(User)
            .values(auth_subject=subject)
            .on_conflict_do_nothing(index_elements=[User.auth_subject])
        )
        user = (await session.scalars(query)).one()
        await session.commit()
    return user
