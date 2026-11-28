from pathlib import Path
from sentence_transformers import SentenceTransformer
import re
import json
import os

# This code finds and reads the file.
repo_root = Path(__file__).resolve().parents[1]
sources = sorted((repo_root / "docs").glob("*.md"))
model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2", device="cpu")
rows = []

for source in sources:
    doc_source = source.relative_to(repo_root).as_posix()
    text = source.read_text(encoding = "utf-8")
    headings = list(re.finditer(r"^##[ \t]+", text, re.MULTILINE))

    for chunk_number, heading in enumerate(headings):
        if chunk_number + 1 < len(headings):
            end = headings[chunk_number + 1].start()

        else:
            end = len(text)

        context = text[heading.start():end].strip()

        embedding = model.encode(context)
        if len(embedding) != 384:
            raise ValueError(f"Chunk {chunk_number} has {len(embedding)} embedding values, must be 384.")
        print(f"Chunk {chunk_number} embedding dimensions: {len(embedding)}")

        doc_source = source.relative_to(repo_root).as_posix()
        rows.append((doc_source, chunk_number, context, json.dumps(embedding.tolist())))

        print(f"doc_source: {doc_source}")
        print(f"chunk_number: {chunk_number}")
        print(f"context:\n{context}\n")

print(f"Total chunks across all documents: {len(rows)}")

database_url = os.environ.get("DATABASE_URL")
if not database_url:
    print(f"Preview complete. Make sure to set DATABASE_URL to write chunks to PostgreSQL, {len(rows)} have been prepared.")

else:
    import psycopg

    with psycopg.connect(database_url) as connection:
        with connection.cursor() as cursor:
            cursor.executemany(
                """
                INSERT INTO document_chunks (doc_source, chunk_number, context, embedding)
                VALUES (%s, %s, %s, %s::vector)
                ON CONFLICT (doc_source, chunk_number)
                DO UPDATE SET
                    context = EXCLUDED.context,
                    embedding = EXCLUDED.embedding
                """,
                rows,
            )
    
    print(f"Saved {len(rows)} chunks to PostgreSQL.")