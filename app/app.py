import os
import socket
import requests
import psycopg2
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

# pulls db settings from env vars so we don't hardcode passwords in git
DB_HOST = os.getenv("DB_HOST","rag-db")
DB_PORT = os.getenv("DB_PORT","5432")
DB_NAME = os.getenv("DB_NAME","ragdb")
DB_USER = os.getenv("DB_USER","raguser")
DB_PASS = os.getenv("DB_PASSWORD","")

# nginx listens on 11435 internally and load balances between ollama 1 and 2
AI_URL = os.getenv("AI_LB_URL", "http://nginx:11435")
MODEL = os.getenv("LLM_MODEL", "llama3.2:1b")
EMBED_MODEL = os.getenv("EMBED_MODEL", "nomic-embed-text")

# grab this container's hostname so we can tell which replica answered a request
HOST_ID = socket.gethostname()

# open a new connection to the postgres/pgvector container
def connect_db():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        connect_timeout=5,
    )

# runs after every request to attach the container id in the response headers
@app.after_request
def set_header(res):

    res.headers["X-Container-ID"] = HOST_ID
    return res


@app.route("/")
def home():
    return render_template("index.html", host_id=HOST_ID)

# docker health check hits this every 15s
@app.route("/health")
def health():
    try:
        conn = connect_db()
        cur = conn.cursor()
        cur.execute("SELECT 1;")
        cur.close()
        conn.close()
        return jsonify({"status": "ok", "host": HOST_ID}), 200
    except Exception as e:
        return jsonify({"status": "error", "msg": str(e)}), 503


# returns the list of indexed filenames from postgres
@app.route("/api/docs")
def get_doc():
    try:
        conn = connect_db()
        cur = conn.cursor()
        cur.execute("SELECT DISTINCT source FROM documents ORDER BY source LIMIT 50;")
        docs = [row[0] for row in cur.fetchall()]
        cur.close()
        conn.close()
        return jsonify({"sources": docs, "host": HOST_ID})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# sends user question to local ollama embedding model and returns the vector
def embed_text(txt):
    r = requests.post(
        f"{AI_URL}/api/embeddings",
        json={"model": EMBED_MODEL, "prompt": txt},
        timeout=30,
    )
    r.raise_for_status()
    return r.json()["embedding"]

# searches pgvector 
def find_similar(vec, k=3):
    conn = connect_db()
    cur = conn.cursor()
    cur.execute(
        "SELECT source, content FROM documents ORDER BY embedding <=> %s::vector LIMIT %s;",
        (str(vec), k),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows

# main RAG endpoint
@app.route("/api/ask", methods=["POST"])
def ask():
    body = request.get_json(silent=True) or {}
    q = body.get("question", "").strip()

    if not q:
        return jsonify({"error": "Question cannot be empty"}), 400

    # first step: turn question into vector using local ollama 
    try:
        vec = embed_text(q)
    except Exception:
        return jsonify({
            "error": "AI service is currently down. Please try again later. Other parts of the app are still working.",
            "host": HOST_ID
        }), 503

    # second step: pulls the 3 most relevant document chuncks from postgres
    try:
        rows = find_similar(vec, 3)
    except Exception as e:
        return jsonify({"error": "DB query failed: " + str(e)}), 500

    # combines chunks into one context block and keeps list of sources to show user
    context = ""
    sources = []
    for src, content in rows:
        context += f"[{src}]\n{content}\n\n"
        sources.append(src)
    sources = list(set(sources))

    # tells model to stick to the context
    prompt = (
        "Use only the context below to answer the question. "
        "If it is not in the context, say you do not know. \n\n"
        f"Context:\n{context}\nQuestion: {q}\nAnswer:"
    )

    # third step: sends prompt to local llm
    try:
        r = requests.post(
            f"{AI_URL}/api/generate",
            json={"model": MODEL, "prompt": prompt, "stream": False},
            timeout=300,
        )
        r.raise_for_status()
        ans = r.json().get("response", "").strip()
    except Exception:
        return jsonify({
            "error": "AI service is currently unavailable. Try again in a minute.",
            "host": HOST_ID
        }), 503
    
    return jsonify({"answer": ans, "sources": sources, "host": HOST_ID})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)