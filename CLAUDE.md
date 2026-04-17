# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **configuration-only** repository for a production n8n deployment. There is no custom application code — it uses the official `n8nio/n8n:stable` Docker image. The primary artifacts are Docker Compose orchestration, a Caddy reverse proxy config, a LINE bot workflow, and system optimization scripts.

## Common Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f n8n
docker compose logs -f caddy

# Check service status
docker compose ps

# Run cleanup manually (normally a cron job)
bash ops/cleanup_cron.sh

# System setup (run once on a new host)
bash optimize/docker.sh    # Configure Docker daemon (requires restart)
bash optimize/memory.sh    # Setup swap and sysctl tuning
```

## Architecture

Three-service Docker Compose stack:

```
Internet → Caddy (ports 80/443) → n8n (port 5678) → Redis (queue/session)
                                        ↓
                               ~/n8n-data/ (persistent volume)
```

- **Caddy**: Reverse proxy with automatic TLS, HSTS, and security headers. Config in `Caddyfile`.
- **n8n**: Automation engine running the "Fushimi Bot" workflow. Config entirely via environment variables in `.env` (not tracked in git).
- **Redis**: Backs both the n8n execution queue and LangChain conversation memory (session TTL: 1 hour).

## Environment Variables

The `.env` file (gitignored) must be created on the host. Key variables used in `docker-compose.yml`:

- `TIMEZONE` — Server timezone (e.g., `Asia/Taipei`)
- `N8N_BASIC_AUTH_USER` / `N8N_BASIC_AUTH_PASSWORD` — UI authentication
- Redis credentials as referenced in the compose file

## Key Configuration Decisions

- **Concurrency**: Max 2 simultaneous workflow executions (resource constraint)
- **Execution data**: Only saved on error; successful runs deleted after 24 hours
- **Execution timeout**: 5 min default, 10 min hard limit
- **Memory budgets**: n8n ≤ 450MB, Redis ≤ 140MB, Caddy ≤ 80MB
- **Logging**: n8n log level is `error` only to minimize I/O

## Fushimi Bot Workflow (`workflow.json`)

A LINE messaging bot with AI:
1. Webhook at `/line-bot` receives LINE events
2. JavaScript Code node validates and extracts message/user data
3. LangChain AI Agent using **Claude Sonnet** (Anthropic) with Redis-backed chat memory
4. Agent can call OpenWeather API; system prompt is in Traditional Chinese for Taiwan users

To import or update the workflow, use the n8n UI or the n8n CLI inside the container:
```bash
docker compose exec n8n n8n import:workflow --input=/path/to/workflow.json
```

## Maintenance

`ops/cleanup_cron.sh` is intended to run as a daily cron job. It:
- Prunes Docker images/containers older than 24h
- Deletes execution files from `~/n8n-data/.n8n/executions/` older than 1 day
- Vacuums system journal logs older than 2 days
