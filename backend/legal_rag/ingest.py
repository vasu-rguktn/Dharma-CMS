"""
Ingest PDFs from ./data into a persistent Chroma DB at ./chroma_db.

This script is intentionally lightweight (no LangChain needed).
It uses:
  - pypdf to extract text
  - sentence-transformers for embeddings (default all-MiniLM-L6-v2)
  - chromadb PersistentClient for storage

Run:
  cd backend
  python3 legal_rag/ingest.py
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Iterable, List, Tuple

import chromadb
from chromadb.config import Settings
from pypdf import PdfReader
from sentence_transformers import SentenceTransformer


BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
DB_DIR = BASE_DIR / "chroma_db"


def iter_pdfs(folder: Path) -> Iterable[Path]:
    for p in sorted(folder.glob("*.pdf")):
        if p.is_file():
            yield p


def read_pdf_text(pdf_path: Path) -> str:
    reader = PdfReader(str(pdf_path))
    parts: List[str] = []
    for page in reader.pages:
        txt = page.extract_text() or ""
        if txt.strip():
            parts.append(txt)
    return "\n\n".join(parts).strip()


def chunk_text(text: str, chunk_size: int = 1000, chunk_overlap: int = 200) -> List[str]:
    # Simple character windowing chunker.
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    if not text.strip():
        return []

    chunks: List[str] = []
    start = 0
    n = len(text)
    while start < n:
        end = min(n, start + chunk_size)
        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)
        if end == n:
            break
        start = max(0, end - chunk_overlap)
    return chunks


def main() -> None:
    embedding_model = os.getenv("LEGAL_RAG_EMBEDDING_MODEL", "all-MiniLM-L6-v2")
    collection_name = os.getenv("LEGAL_RAG_COLLECTION", "langchain")
    chunk_size = int(os.getenv("LEGAL_RAG_CHUNK_SIZE", "1000"))
    chunk_overlap = int(os.getenv("LEGAL_RAG_CHUNK_OVERLAP", "200"))

    DATA_DIR.mkdir(parents=True, exist_ok=True)
    DB_DIR.mkdir(parents=True, exist_ok=True)

    pdfs = list(iter_pdfs(DATA_DIR))
    if not pdfs:
        raise SystemExit(f"No PDFs found in {DATA_DIR}")

    print(f"Embedding model: {embedding_model}")
    print(f"Chroma DB path:  {DB_DIR}")
    print(f"Collection:     {collection_name}")
    print(f"PDFs found:     {len(pdfs)}")

    embedder = SentenceTransformer(embedding_model)

    client = chromadb.PersistentClient(
        path=str(DB_DIR),
        settings=Settings(anonymized_telemetry=False, allow_reset=True),
    )
    # Reset the DB/collection for a clean rebuild
    try:
        client.reset()
    except Exception as e:
        print(f"Warning: client.reset() failed: {e}")

    collection = client.get_or_create_collection(name=collection_name)

    ids: List[str] = []
    docs: List[str] = []
    metas: List[dict] = []

    total_chunks = 0
    for pdf_path in pdfs:
        print(f"Reading: {pdf_path.name}")
        text = read_pdf_text(pdf_path)
        chunks = chunk_text(text, chunk_size=chunk_size, chunk_overlap=chunk_overlap)
        print(f"  chunks: {len(chunks)}")
        for idx, chunk in enumerate(chunks):
            doc_id = f"{pdf_path.name}::chunk::{idx}"
            ids.append(doc_id)
            docs.append(chunk)
            metas.append(
                {
                    "source": pdf_path.name,
                    "chunk_index": idx,
                }
            )
        total_chunks += len(chunks)

    print(f"Total chunks: {total_chunks}")

    # Embed + upsert in batches
    batch_size = 128
    for i in range(0, len(docs), batch_size):
        batch_docs = docs[i : i + batch_size]
        batch_ids = ids[i : i + batch_size]
        batch_metas = metas[i : i + batch_size]
        embs = embedder.encode(batch_docs, normalize_embeddings=True).tolist()
        collection.add(documents=batch_docs, metadatas=batch_metas, embeddings=embs, ids=batch_ids)
        print(f"Upserted batch {i // batch_size + 1} / {(len(docs) + batch_size - 1) // batch_size}")

    print(f"Done. Collection count = {collection.count()}")


if __name__ == "__main__":
    main()

