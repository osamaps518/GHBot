"""create users

Revision ID: 7bf049bc5c26
Revises:
Create Date: 2026-10-20 10:42:41.244614
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "7bf049bc5c26"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("auth_subject", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("auth_subject"),
    )


def downgrade() -> None:
    op.drop_table("users")
