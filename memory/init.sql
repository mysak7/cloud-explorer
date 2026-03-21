CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS memories (
    id          SERIAL PRIMARY KEY,
    content     TEXT NOT NULL,
    tags        TEXT[],
    embedding   vector(1536),
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS memories_embedding_idx
    ON memories
    USING hnsw (embedding vector_cosine_ops);
