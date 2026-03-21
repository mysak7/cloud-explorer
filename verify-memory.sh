#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo " AWS Explorer Agent — Memory Verify"
echo "============================================"
echo ""

echo "--- [1/3] PostgreSQL reachability ---"
if docker compose exec pgvector pg_isready -U agent; then
  echo "PostgreSQL: OK"
else
  echo "PostgreSQL: FAILED — check pgvector service logs: docker compose logs pgvector"
  exit 1
fi

echo ""
echo "--- [2/3] memories table ---"
docker compose exec pgvector psql -U agent -d agent_memory -c "\dt"

echo ""
echo "--- [3/3] pgvector extension ---"
docker compose exec pgvector psql -U agent -d agent_memory -c "SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';"

echo ""
echo "============================================"
echo " Memory verification complete."
echo "============================================"
