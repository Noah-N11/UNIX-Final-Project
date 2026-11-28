CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS document_chunks (
    doc_source TEXT NOT NULL,
    chunk_number  INTEGER NOT NULL CHECK (chunk_number >= 0),
    context TEXT NOT NULL,
    embedding vector(384) NOT NULL,
    PRIMARY KEY (doc_source, chunk_number)
);