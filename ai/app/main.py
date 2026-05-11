from fastapi import FastAPI, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import text

from .db import SessionLocal, engine, Base
from .models import BookChunk
from .indexing import build_chunks, embed_texts
from .retrieval import search_chunks
from .llm import answer_question

app = FastAPI(title="Education History AI API")

class QuestionRequest(BaseModel):
    question: str

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.on_event("startup")
def startup():
    with engine.begin() as conn:
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
    Base.metadata.create_all(bind=engine)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/index")
def index_book(db: Session = Depends(get_db)):
    db.query(BookChunk).delete()
    db.commit()

    chunks = build_chunks()
    if not chunks:
      return {
          "message": "No education history chunks found to index.",
          "pages_indexed": 0,
          "chunks_indexed": 0,
      }

    embeddings = embed_texts([chunk["content"] for chunk in chunks])

    for chunk, embedding in zip(chunks, embeddings):
        record = BookChunk(
            page_id=chunk["page_id"],
            title=chunk["title"],
            url=chunk["url"],
            chapter=chunk["chapter"],
            chunk_index=chunk["chunk_index"],
            content=chunk["content"],
            embedding=embedding,
        )
        db.add(record)

    db.commit()

    return {
        "message": "Education history indexing complete.",
        "pages_indexed": len(set(chunk["page_id"] for chunk in chunks)),
        "chunks_indexed": len(chunks),
    }

@app.post("/ask")
def ask(request: QuestionRequest, db: Session = Depends(get_db)):
    chunks = search_chunks(db, request.question, limit=5)
    answer = answer_question(request.question, chunks)

    return {
        "question": request.question,
        "answer": answer,
        "sources": [
            {
                "title": chunk["title"],
                "url": chunk["url"],
                "chunk_index": chunk["chunk_index"],
            }
            for chunk in chunks
        ],
    }