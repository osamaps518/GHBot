"""Index food log pulls by trainee and update time.

Revision ID: b85c92fd1a40
Revises: 7b5a089d90c6
"""

from collections.abc import Sequence

from alembic import op

revision: str = "b85c92fd1a40"
down_revision: str | Sequence[str] | None = "7b5a089d90c6"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_index(
        "ix_food_log_entries_user_updated",
        "food_log_entries",
        ["user_id", "updated_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_food_log_entries_user_updated", table_name="food_log_entries")
