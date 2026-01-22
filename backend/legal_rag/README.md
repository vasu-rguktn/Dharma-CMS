## Legal RAG assets (local-only)

Put your law PDFs here:

- `backend/legal_rag/data/`

Build the local Chroma vector DB here (generated):

- `backend/legal_rag/chroma_db/`

### Ingest PDFs into Chroma

From `backend/`:

```bash
python3 legal_rag/ingest.py
```

### Run backend with Legal RAG enabled

```bash
export LEGAL_RAG_ENABLED=true
export LEGAL_RAG_DB_PATH="$(pwd)/legal_rag/chroma_db"
export LEGAL_RAG_COLLECTION="langchain"
export LEGAL_RAG_EMBEDDING_MODEL="all-MiniLM-L6-v2"
```

> `data/` and `chroma_db/` are ignored by git (see repo `.gitignore`).

