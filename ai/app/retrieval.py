from sqlalchemy import text
from sentence_transformers import SentenceTransformer

EMBED_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
_model = None

def get_model():
    global _model
    if _model is None:
        _model = SentenceTransformer(EMBED_MODEL_NAME)
    return _model

def embed_query(query: str) -> list[float]:
    model = get_model()
    return model.encode([query], normalize_embeddings=True)[0].tolist()

def search_chunks(db, query: str, limit: int = 5):
    query_embedding = embed_query(query)

    sql = text("""
        SELECT id, page_id, title, url, chapter, chunk_index, content,
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