import os
from functools import lru_cache
from pathlib import Path
from typing import List, Tuple

import chromadb
from chromadb.config import Settings
from sentence_transformers import SentenceTransformer


DEFAULT_COLLECTION_NAME = "langchain"


def _env_bool(name: str, default: bool = False) -> bool:
    val = os.getenv(name)
    if val is None:
        return default
    return val.strip().lower() in {"1", "true", "yes", "y", "on"}


@lru_cache(maxsize=1)
def _get_embedder() -> SentenceTransformer:
    # Must match the embedding model used to build the Chroma DB.
    # `nikki_rag` defaults to "all-MiniLM-L6-v2" with normalized embeddings.
    model_name = os.getenv("LEGAL_RAG_EMBEDDING_MODEL", "all-MiniLM-L6-v2")
    return SentenceTransformer(model_name)


@lru_cache(maxsize=1)
def _get_collection():
    # Default to repo-local DB: backend/legal_rag/chroma_db
    default_db_path = str((Path(__file__).resolve().parents[1] / "legal_rag" / "chroma_db"))
    db_path = os.getenv("LEGAL_RAG_DB_PATH", default_db_path)

    os.makedirs(db_path, exist_ok=True)

    client = chromadb.PersistentClient(
        path=db_path,
        settings=Settings(anonymized_telemetry=False, allow_reset=False),
    )
    collection_name = os.getenv("LEGAL_RAG_COLLECTION", DEFAULT_COLLECTION_NAME)
    return client.get_or_create_collection(collection_name)


def rag_enabled() -> bool:
    return _env_bool("LEGAL_RAG_ENABLED", default=False)


def retrieve_context(query: str, top_k: int = 4) -> Tuple[str, List[dict]]:
    """
    Returns:
      - context_text: concatenated retrieved documents
      - sources: list of metadata dicts (best-effort)
    """
    embedder = _get_embedder()
    collection = _get_collection()

    query_embedding = embedder.encode([query], normalize_embeddings=True)[0].tolist()

    result = collection.query(
        query_embeddings=[query_embedding],
        n_results=top_k,
        include=["documents", "metadatas", "distances"],
    )

    docs = (result.get("documents") or [[]])[0] or []
    metas = (result.get("metadatas") or [[]])[0] or []
    distances = (result.get("distances") or [[]])[0] or []

    # Build a readable context block
    chunks: List[str] = []
    sources: List[dict] = []
    for i, doc in enumerate(docs):
        meta = metas[i] if i < len(metas) else {}
        dist = distances[i] if i < len(distances) else None
        sources.append(
            {
                "rank": i + 1,
                "distance": dist,
                "metadata": meta,
            }
        )
        chunks.append(f"[Source {i+1}]\n{doc}".strip())

    context_text = "\n\n".join(chunks).strip()
    return context_text, sources

