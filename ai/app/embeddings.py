"""Turning text into vectors.

This is the only place in the service that produces an embedding. Indexing and
searching must use the same model: vectors from two different models describe
two different coordinate spaces, and comparing across them yields nonsense
rather than an error. Keeping both callers behind one module makes that rule
structural instead of a comment nobody reads.

The work is done by Ollama, which is already running to write answers. Using
it for embeddings too means the service needs no local machine-learning
runtime at all -- no torch, no sentence-transformers -- which is most of the
reason this container is small.
"""

import os
import requests

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://ai-ollama-lib-unb-ca:11434")

# all-minilm is all-MiniLM-L6-v2, the same model this service used to load
# locally: 384 dimensions, which is why models.py declares Vector(384).
OLLAMA_EMBED_MODEL = os.getenv("OLLAMA_EMBED_MODEL", "all-minilm")

# How many chunks to send per HTTP request. One request for the whole book
# would work but gives no feedback for minutes at a time; one request per
# chunk would pay the round-trip cost ~1500 times.
EMBED_BATCH_SIZE = 64


def embed_texts(texts: list[str]) -> list[list[float]]:
    """Embed many strings, in batches, preserving input order."""
    vectors: list[list[float]] = []

    for start in range(0, len(texts), EMBED_BATCH_SIZE):
        batch = texts[start:start + EMBED_BATCH_SIZE]

        response = requests.post(
            f"{OLLAMA_BASE_URL}/api/embed",
            json={
                "model": OLLAMA_EMBED_MODEL,
                "input": batch,
            },
            timeout=300,
        )
        response.raise_for_status()

        vectors.extend(response.json()["embeddings"])
        print(f"Embedded {len(vectors)}/{len(texts)} chunks.", flush=True)

    return vectors


def embed_query(query: str) -> list[float]:
    """Embed a single question, using the model that embedded the book."""
    return embed_texts([query])[0]
