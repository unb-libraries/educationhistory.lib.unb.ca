from sqlalchemy import Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from pgvector.sqlalchemy import Vector
from .db import Base

class BookChunk(Base):
    __tablename__ = "book_chunks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # The Drupal node this text came from -- a whole chapter. Named node_id,
    # not page_id, because "page" now means a printed page of the 1947
    # edition, which is a much smaller thing.
    node_id: Mapped[int] = mapped_column(Integer, index=True)

    title: Mapped[str] = mapped_column(String(500))

    # Anchored link to the passage in the web text, e.g. /MacNcha4#p35.
    url: Mapped[str] = mapped_column(String(1000))

    # The printed page number, as it appears in the 1947 book. Nullable: front
    # matter and the table of contents carry no pagination.
    printed_page: Mapped[str | None] = mapped_column(String(20), nullable=True)

    # Deep link to the same page of the scanned original PDF.
    scan_url: Mapped[str | None] = mapped_column(String(1000), nullable=True)

    chunk_index: Mapped[int] = mapped_column(Integer)
    content: Mapped[str] = mapped_column(Text)
    embedding: Mapped[list[float]] = mapped_column(Vector(384))
