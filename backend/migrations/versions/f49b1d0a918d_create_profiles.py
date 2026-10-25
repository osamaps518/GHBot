"""create profiles

Revision ID: f49b1d0a918d
Revises: 7bf049bc5c26
Create Date: 2026-10-25 09:36:30.125975
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "f49b1d0a918d"
down_revision: str | Sequence[str] | None = "7bf049bc5c26"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "profiles",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("birth_year", sa.Integer(), nullable=False),
        sa.Column("birth_month", sa.Integer(), nullable=False),
        sa.Column("sex", sa.Text(), nullable=False),
        sa.Column("height_cm", sa.Float(precision=53), nullable=False),
        sa.Column("weight_kg", sa.Float(precision=53), nullable=False),
        sa.Column("activity_level", sa.Text(), nullable=False),
        sa.Column("goal", sa.Text(), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
        ),
        sa.PrimaryKeyConstraint("user_id"),
    )


def downgrade() -> None:
    op.drop_table("profiles")
