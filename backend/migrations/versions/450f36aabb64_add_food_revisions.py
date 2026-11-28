"""add food revisions

Revision ID: 450f36aabb64
Revises: 2c135c5b1fc5
Create Date: 2026-11-28 13:07:35.841659
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "450f36aabb64"
down_revision: str | Sequence[str] | None = "2c135c5b1fc5"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "foods",
        sa.Column(
            "revision", sa.Integer(), server_default=sa.text("0"), nullable=False
        ),
    )


def downgrade() -> None:
    op.drop_column("foods", "revision")
