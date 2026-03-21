# AWS Explorer — Quick Ops

All commands run from the repo root: `~/GitHub/aws-explorer`

## Rebuild the agent container

After changing `Dockerfile`, `requirements.txt`, or any baked-in file:

```bash
# Rebuild and restart agent only
docker compose up -d --build agent

# Full rebuild from scratch (no cache)
docker compose build --no-cache agent && docker compose up -d
```

## Restart MCP servers

The MCP servers (`aws-agent-memory`, `awslabs-*`) are stdio processes spawned by Claude Code — not separate Docker services. To restart them, restart the container:

```bash
docker compose restart agent
```

Claude Code re-spawns all MCP processes on the next launch.

## Connect to the agent container

```bash
# Shell into the running container
docker compose exec agent bash

# Then start Claude Code inside
cd /workspace && claude
```

## Quick status check

```bash
docker compose ps               # all service states
docker compose logs -f agent    # agent logs
docker compose logs -f pgvector # memory DB logs
```
