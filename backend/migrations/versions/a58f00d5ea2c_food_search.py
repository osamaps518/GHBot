"""food search

Revision ID: a58f00d5ea2c
Revises: c3526dbdb09f
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "a58f00d5ea2c"
down_revision: str | Sequence[str] | None = "c3526dbdb09f"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    op.execute("""
        CREATE FUNCTION food_search_clean(t text) RETURNS text
        LANGUAGE sql IMMUTABLE PARALLEL SAFE
        AS $$
            SELECT translate(
                regexp_replace(
                    normalize(normalize(lower(t), NFKC), NFD),
                    '[\u0300-\u036f\u0640\u064b-\u065f\u0670]', '', 'g'
                ),
                'أإآٱةىئیک٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹',
                'ااااهيييك01234567890123456789'
            )
        $$
    """)
    op.execute("""
        CREATE FUNCTION food_search_names(ar text, en text, others text[])
        RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE
        AS $$
            SELECT array_to_string(
                ARRAY(
                    SELECT food_search_clean(name)
                    FROM unnest(ARRAY[ar, en] || others) AS name
                    WHERE name IS NOT NULL AND name <> ''
                ),
                ' | '
            )
        $$
    """)
    op.add_column(
        "foods",
        sa.Column(
            "search",
            sa.Text(),
            sa.Computed(
                "food_search_names(name_ar, name_en, other_names)", persisted=True
            ),
            nullable=False,
        ),
    )
    op.create_index(
        "ix_foods_search_trgm",
        "foods",
        ["search"],
        postgresql_using="gin",
        postgresql_ops={"search": "gin_trgm_ops"},
    )


def downgrade() -> None:
    op.drop_index("ix_foods_search_trgm", table_name="foods")
    op.drop_column("foods", "search")
    op.execute("DROP FUNCTION food_search_names(text, text, text[])")
    op.execute("DROP FUNCTION food_search_clean(text)")
    op.execute("DROP EXTENSION pg_trgm")
