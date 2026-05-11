import re
from sentence_transformers import SentenceTransformer
from .drupal_client import fetch_book_pages

EMBED_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
_model = None

def get_model():
    global _model
    if _model is None:
        _model = SentenceTransformer(EMBED_MODEL_NAME)
    return _model

def normalize_text(text: str) -> str:
    text = text or ""
    text = re.sub(r"\s+", " ", text)
    return text.strip()

def chunk_text(text: str, chunk_size: int = 1200, overlap: int = 200) -> list[str]:
    text = normalize_text(text)
    if not text:
        return []

    chunks = []
    start = 0

    while start < len(text):
        end = start + chunk_size
        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)
        start += chunk_size - overlap

    return chunks

def build_chunks():
    pages = fetch_book_pages()
    all_chunks = []

    for page in pages:
        body = normalize_text(page.get("body", ""))
        if not body:
            continue

        text_chunks = chunk_text(body)

        for i, chunk in enumerate(text_chunks):
            all_chunks.append({
                "page_id": page["id"],
                "title": page["title"],
                "url": page["url"],
                "chapter": str(page.get("book_parent") or ""),
                "chunk_index": i,
                "content": chunk,
            })

    return all_chunks

def embed_texts(texts: list[str]) -> list[list[float]]:
    model = get_model()
    return model.encode(texts, normalize_embeddings=True).tolist()