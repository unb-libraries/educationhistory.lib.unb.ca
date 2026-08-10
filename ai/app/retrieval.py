from sqlalchemy import text
from .embeddings import embed_query


def search_chunks(db, query: str, limit: int = 5):
    query_embedding = embed_query(query)

    # "<=>" is pgvector's cosine distance operator: 0 means identical
    # direction, 1 means unrelated, 2 means opposite. Being a distance, smaller
    # is better, hence a plain ascending ORDER BY. Cosine ignores vector
    # length, so the embeddings do not need to be normalized first.
    #
    # With ~1400 rows this scans the whole table, which takes under a
    # millisecond. An ivfflat or hnsw index would only start paying for itself
    # a couple of orders of magnitude further up.
    sql = text("""
        SELECT id, node_id, title, url, printed_page, scan_url, chunk_index, content,
               embedding <=> CAST(:embedding AS vector) AS distance
        FROM book_chunks
        ORDER BY embedding <=> CAST(:embedding AS vector)
        LIMIT :limit
    """)

    result = db.execute(sql, {
        "embedding": str(query_embedding),
        "limit": limit,
    })

    return [dict(row._mapping) for row in result]
