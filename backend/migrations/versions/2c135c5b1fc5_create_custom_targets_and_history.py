"""Create custom targets and history.

Revision ID: 2c135c5b1fc5
Revises: b85c92fd1a40
Create Date: 2026-11-28 06:50:53.751333
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "2c135c5b1fc5"
down_revision: str | Sequence[str] | None = "b85c92fd1a40"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "custom_targets",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("calories", sa.Integer(), nullable=False),
        sa.Column("protein_g", sa.Integer(), nullable=False),
        sa.Column("fat_g", sa.Integer(), nullable=False),
        sa.Column("carbs_g", sa.Integer(), nullable=False),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("clock_timestamp()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("user_id"),
    )
    op.create_table(
        "target_history",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("kind", sa.Text(), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("recommended_calories", sa.Integer(), nullable=False),
        sa.Column("recommended_protein_g", sa.Integer(), nullable=False),
        sa.Column("recommended_fat_g", sa.Integer(), nullable=False),
        sa.Column("recommended_carbs_g", sa.Integer(), nullable=False),
        sa.Column("custom_calories", sa.Integer(), nullable=False),
        sa.Column("custom_protein_g", sa.Integer(), nullable=False),
        sa.Column("custom_fat_g", sa.Integer(), nullable=False),
        sa.Column("custom_carbs_g", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("target_history")
    op.drop_table("custom_targets")
