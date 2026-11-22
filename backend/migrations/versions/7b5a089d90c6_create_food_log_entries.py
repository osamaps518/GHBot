"""create food log entries

Revision ID: 7b5a089d90c6
Revises: a58f00d5ea2c
Create Date: 2026-11-22 07:24:45.263866
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "7b5a089d90c6"
down_revision: str | Sequence[str] | None = "a58f00d5ea2c"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "food_log_entries",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("food_id", sa.Uuid(), nullable=True),
        sa.Column("meal", sa.Text(), nullable=True),
        sa.Column("meal_name", sa.Text(), nullable=True),
        sa.Column("diary_day", sa.Date(), nullable=True),
        sa.Column("grams", sa.Numeric(precision=10, scale=1), nullable=True),
        sa.Column("logged_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "calories_per_100g", sa.Numeric(precision=10, scale=1), nullable=True
        ),
        sa.Column("protein_per_100g", sa.Numeric(precision=10, scale=1), nullable=True),
        sa.Column("carbs_per_100g", sa.Numeric(precision=10, scale=1), nullable=True),
        sa.Column("fat_per_100g", sa.Numeric(precision=10, scale=1), nullable=True),
        sa.Column("calories", sa.Numeric(precision=10, scale=1), nullable=True),
        sa.Column("protein", sa.Numeric(precision=10, scale=1), nullable=True),
        sa.Column("carbs", sa.Numeric(precision=10, scale=1), nullable=True),
        sa.Column("fat", sa.Numeric(precision=10, scale=1), nullable=True),
        sa.Column("revision", sa.Integer(), nullable=False),
        sa.Column("deleted", sa.Boolean(), nullable=False),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("clock_timestamp()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "(meal = 'extra' AND meal_name IS NOT NULL AND length(trim(meal_name)) BETWEEN 1 AND 40) OR (meal IS DISTINCT FROM 'extra' AND meal_name IS NULL)",
            name="food_log_meal_name",
        ),
        sa.CheckConstraint(
            "meal IS NULL OR meal IN ('breakfast', 'lunch', 'dinner', 'extra')",
            name="food_log_meal_allowed",
        ),
        sa.CheckConstraint(
            "deleted OR (revision >= 1 AND food_id IS NOT NULL AND meal IS NOT NULL AND diary_day IS NOT NULL AND grams IS NOT NULL AND logged_at IS NOT NULL AND calories_per_100g IS NOT NULL AND protein_per_100g IS NOT NULL AND carbs_per_100g IS NOT NULL AND fat_per_100g IS NOT NULL AND calories IS NOT NULL AND protein IS NOT NULL AND carbs IS NOT NULL AND fat IS NOT NULL)",
            name="food_log_active_values",
        ),
        sa.CheckConstraint("revision >= 0", name="food_log_revision_nonnegative"),
        sa.ForeignKeyConstraint(
            ["food_id"],
            ["foods.id"],
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("food_log_entries")
