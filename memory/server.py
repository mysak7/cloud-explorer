import json
import logging
import os

import boto3
import psycopg2
from fastmcp import FastMCP

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PG_CONNECTION_STRING = os.environ.get(
    "PG_CONNECTION_STRING",
    "postgresql://agent:agent_password@pgvector:5432/agent_memory",
)
AWS_REGION = os.environ.get("AWS_REGION", "eu-central-1")

mcp = FastMCP("aws-agent-memory")


def get_embedding(text: str) -> list[float]:
    client = boto3.client("bedrock-runtime", region_name=AWS_REGION)
    body = json.dumps({"inputText": text, "dimensions": 1024, "normalize": True})
    response = client.invoke_model(
        modelId="amazon.titan-embed-text-v2:0",
        contentType="application/json",
        accept="application/json",
        body=body,
    )
    return json.loads(response["body"].read())["embedding"]


def get_db_connection():
    conn = psycopg2.connect(PG_CONNECTION_STRING)
    return conn


def to_pg_vector(embedding: list[float]) -> str:
    """Convert a float list to a PostgreSQL vector literal string."""
    return "[" + ",".join(str(x) for x in embedding) + "]"


@mcp.tool()
def store_memory(content: str, tags: list[str] = []) -> str:
    """Store a memory with optional tags. Content is embedded and saved to pgvector."""
    embedding = get_embedding(content)
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO memories (content, tags, embedding) VALUES (%s, %s, %s::vector) RETURNING id",
                (content, tags, to_pg_vector(embedding)),
            )
            row_id = cur.fetchone()[0]
            conn.commit()
    finally:
        conn.close()
    return f"Memory stored with id {row_id}"


@mcp.tool()
def search_memory(query: str, limit: int = 5) -> str:
    """Search memories by semantic similarity to a query string."""
    embedding = get_embedding(query)
    vec = to_pg_vector(embedding)
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, content, tags, 1 - (embedding <=> %s::vector) AS similarity
                FROM memories
                ORDER BY embedding <=> %s::vector
                LIMIT %s
                """,
                (vec, vec, limit),
            )
            rows = cur.fetchall()
    finally:
        conn.close()

    if not rows:
        return "No memories found."

    lines = []
    for row_id, content, tags, similarity in rows:
        lines.append(
            f"[id={row_id}] (similarity={similarity:.3f})\n"
            f"  tags: {tags}\n"
            f"  content: {content}"
        )
    return "\n\n".join(lines)


@mcp.tool()
def list_memories(tag: str = "") -> str:
    """List stored memories, optionally filtered by tag."""
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            if tag:
                cur.execute(
                    """
                    SELECT id, content, tags, created_at
                    FROM memories
                    WHERE %s = ANY(tags)
                    ORDER BY created_at DESC
                    LIMIT 20
                    """,
                    (tag,),
                )
            else:
                cur.execute(
                    """
                    SELECT id, content, tags, created_at
                    FROM memories
                    ORDER BY created_at DESC
                    LIMIT 20
                    """
                )
            rows = cur.fetchall()
    finally:
        conn.close()

    if not rows:
        return "No memories found."

    lines = []
    for row_id, content, tags, created_at in rows:
        preview = content[:100] + ("..." if len(content) > 100 else "")
        lines.append(
            f"[id={row_id}] {created_at.strftime('%Y-%m-%d %H:%M')} tags={tags}\n  {preview}"
        )
    return "\n".join(lines)


if __name__ == "__main__":
    mcp.run(transport="stdio")
