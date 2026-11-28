# GCP Database Setup Guide

## Database Engine
The database service used in our project is PostgreSQL 17 alongside pgvector. Our configured database name is `ragdb`.

## Vector Extension
The 'database-init.sql' initializes the "vector" extension and creates the 'document_chunks' table with these attributes:
- doc_source: The origin path of the document added to our database.
- chunk_number: The chunk's position within its source file, starting at 0. For example, the 3rd generated chunk will have the chunk number 2.
- context: Stores the text contained in the chunk, including its heading.
- embedding: Stores the 384 numbers that are generated from the text. 

Compose file mounts 'database-init.sql' so that 'pgvector' can be enabled and the table can be created when an empty data directory is initialized. The 'ingest.py' script adds or updates the database with the new document information.

## Persistent Storage
The Compose file maps `/data/db' on the host to '/var/lib/postgresql/data' inside the container. On GCP deployment, we will mount a logical volume at '/data/db' before PostgreSQL starts.

## Document Chunks
Each row in 'document_chunks' stores a source path (doc_source), a chunk number (chunk_number), the passage text (context), and a 384-value embedding (embedding). Refer to the 'Vector Extension' for further context on each value. The database's primary key is formed by combining the source path and the chunk number. If ingestion encounters a repeat primary key, it updates the existing rows instead of creating a duplicate.

## Database Access
Our deployed application will use private network access. The database password will be read by Compose from 'POSTGRES_PASSWORD'.