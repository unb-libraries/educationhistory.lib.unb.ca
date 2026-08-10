import re
from .drupal_client import fetch_book_pages

# Chunk size is capped by the embedding model, not by taste. all-MiniLM-L6-v2
# reads at most 256 word-pieces and silently ignores everything after that, so
# an oversized chunk gets stored and shown to the LLM while its tail stays
# invisible to search. Measured on this book's prose, 1200 characters came to
# roughly 260-280 tokens -- over the limit on every chunk. 800 characters lands
# near 200 tokens, safely inside it.
CHUNK_SIZE = 800

# Consecutive chunks overlap so a sentence sitting on a boundary still appears
# intact in at least one of them.
CHUNK_OVERLAP = 200


def normalize_text(text: str) -> str:
    text = text or ""
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def chunk_text(text: str, chunk_size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> list[str]:
    """Split text into overlapping chunks that begin and end on whole words.

    Cutting at an exact character count sliced words in half, so retrieved
    passages opened with fragments like "evate the profession". That is ugly
    in a quoted answer, and it also feeds the embedding model a token that
    does not exist. Backing each boundary up to the nearest space costs a few
    characters and removes both problems.
    """
    text = normalize_text(text)
    if not text:
        return []

    chunks: list[str] = []
    length = len(text)
    start = 0

    while start < length:
        end = min(start + chunk_size, length)

        # Unless this is the final chunk, retreat to the last space so the
        # chunk ends on a word boundary.
        if end < length:
            space = text.rfind(" ", start, end)
            if space > start:
                end = space

        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)

        if end >= length:
            break

        # Step back by the overlap, then forward to the start of a word. The
        # "start + 1" floor guarantees the loop always advances.
        nxt = max(end - overlap, start + 1)
        previous_space = text.rfind(" ", start, nxt)
        if previous_space != -1 and previous_space + 1 > start:
            nxt = previous_space + 1
        start = max(nxt, start + 1)

    return chunks


def build_chunks():
    """Turn the book into chunks, each carrying the citation for its passage.

    Chunking happens within a single printed page and never across two, so
    every chunk can name exactly one page of the 1947 edition. The cost is that
    a sentence spanning a page break is split; the gain is that an answer can
    cite "Chapter 4, p. 35" and link straight to it, rather than gesturing at a
    forty-page chapter.
    """
    nodes = fetch_book_pages()
    all_chunks = []

    for node in nodes:
        # chunk_index runs across the whole node so that chunks stay in
        # reading order regardless of which page they came from.
        chunk_index = 0

        for page in node.get("pages", []):
            for chunk in chunk_text(page.get("text", "")):
                all_chunks.append({
                    "node_id": node["id"],
                    "title": node["title"],
                    "url": page.get("url") or node["url"],
                    "printed_page": page.get("page"),
                    "scan_url": page.get("scan_url"),
                    "chunk_index": chunk_index,
                    "content": chunk,
                })
                chunk_index += 1

    return all_chunks
