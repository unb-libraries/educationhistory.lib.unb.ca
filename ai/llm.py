import os
import requests

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://ollama:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.2:3b")

def answer_question(question: str, chunks: list[dict]) -> str:
    context = "\n\n".join(
        f"Source: {chunk['title']} ({chunk['url']})\n{chunk['content']}"
        for chunk in chunks
    )

    prompt = f"""
You are answering questions about an education history book.

Use only the context provided below.
If the answer is not contained in the context, say:
"I could not find that in the education history excerpts provided."

Be careful, concise, and factual.
When possible, mention the source page title and URL.

Context:
{context}

Question:
{question}

Answer:
""".strip()

    response = requests.post(
        f"{OLLAMA_BASE_URL}/api/generate",
        json={
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "stream": False
        },
        timeout=120,
    )
    response.raise_for_status()
    data = response.json()
    return data["response"]
