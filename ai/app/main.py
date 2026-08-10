from fastapi import FastAPI, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import text

# Import database setup tools.
from .db import SessionLocal, engine, Base

# Import the SQLAlchemy model for stored text chunks.
from .models import BookChunk

# Import the helper that fetches and chunks Drupal content.
from .indexing import build_chunks

# Import the shared embedding helper. Indexing and retrieval both go through
# this module so they cannot drift onto different models.
from .embeddings import embed_texts

# Import retrieval helper for semantic search.
from .retrieval import search_chunks

# Import the function that asks the local LLM for an answer.
from .llm import answer_question

# Create the FastAPI application.
app = FastAPI(title="Education History AI API")

# Define the expected JSON body for the /ask endpoint.
class QuestionRequest(BaseModel):
    question: str

# Create and clean up a database session for each request.
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Run startup tasks when the app launches.
@app.on_event("startup")
def startup():
    # Ensure the pgvector extension exists in PostgreSQL.
    with engine.begin() as conn:
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))

    # Create database tables based on SQLAlchemy models if needed.
    Base.metadata.create_all(bind=engine)

# Simple test endpoint to confirm the API is alive.
@app.get("/health")
def health():
    return {"status": "ok"}

# Index Drupal content into the vector database.
@app.post("/index")
def index_book(db: Session = Depends(get_db)):
    # Remove old indexed chunks to rebuild from scratch.
    db.query(BookChunk).delete()
    db.commit()

    # Fetch and chunk Drupal content.
    chunks = build_chunks()

    # If no chunks were created, stop here.
    if not chunks:
        return {
            "message": "No education history chunks found to index.",
            "pages_indexed": 0,
            "chunks_indexed": 0,
        }

    # Create embeddings for all chunk text.
    embeddings = embed_texts([chunk["content"] for chunk in chunks])

    # Store each chunk and its embedding in the database.
    for chunk, embedding in zip(chunks, embeddings):
        record = BookChunk(
            node_id=chunk["node_id"],
            title=chunk["title"],
            url=chunk["url"],
            printed_page=chunk["printed_page"],
            scan_url=chunk["scan_url"],
            chunk_index=chunk["chunk_index"],
            content=chunk["content"],
            embedding=embedding,
        )
        db.add(record)

    # Save all inserted rows.
    db.commit()

    # Return a summary.
    return {
        "message": "Education history indexing complete.",
        "nodes_indexed": len(set(chunk["node_id"] for chunk in chunks)),
        "printed_pages_indexed": len(
            set(chunk["printed_page"] for chunk in chunks if chunk["printed_page"])
        ),
        "chunks_indexed": len(chunks),
    }

# Answer a user question using retrieval + generation.
@app.post("/ask")
def ask(request: QuestionRequest, db: Session = Depends(get_db)):
    # Retrieve the most relevant chunks from the database.
    chunks = search_chunks(db, request.question, limit=5)

    # Ask the LLM to answer based on those chunks.
    answer = answer_question(request.question, chunks)

    # Return the answer and its sources. Each source now names a single
    # printed page of the 1947 edition and links to it two ways: into the web
    # text at the right anchor, and into the scanned original.
    return {
        "question": request.question,
        "answer": answer,
        "sources": [
            {
                "title": chunk["title"],
                "printed_page": chunk["printed_page"],
                "url": chunk["url"],
                "scan_url": chunk["scan_url"],
                "chunk_index": chunk["chunk_index"],
            }
            for chunk in chunks
        ],
    }