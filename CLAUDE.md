# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`open-clovis` runs Claude Code as a persistent Docker container reachable via Telegram. It is a shell — infrastructure only. The actual work happens in a separate `clovis-workspace` repo mounted at `./data/workspace`.

Two-repo model:
- `open-clovis` — container, auth, Telegram config (this repo, managed from the host)
- `clovis-workspace` — git repo Claude operates on (mounted at `/home/clovis/workspace` inside the container)

## Key files

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the image: node:22, Bun, Claude Code, gh CLI |
| `entrypoint.sh` | Registers plugin marketplace, installs Telegram plugin, configures git credentials, registers n8n MCP servers, starts `claude` |
| `docker-compose.yml` | Two services: `agent` (Claude Code) + `n8n` (workflow automation), both on `clovis-net` |
| `setup.sh` | First-time setup: scaffolds `.env`, prompts for credentials, auto-generates `N8N_ENCRYPTION_KEY` |

## Common commands

```bash
./setup.sh                        # first-time init (prompts for credentials, generates N8N_ENCRYPTION_KEY)
docker compose build              # rebuild image after Dockerfile changes
docker compose run --rm agent     # interactive first-run wizard
docker compose up -d              # start headless
docker compose logs -f            # follow logs
```

## Volume layout

| Host path | Container path | Notes |
|---|---|---|
| `./data` | `/home/clovis` | Home dir — holds `.claude/` config and `.claude.json` |
| `./data/workspace` | `/home/clovis/workspace` | Workspace repo Claude operates on |
| `./n8n-data` | `/home/node/.n8n` (n8n container) | n8n workflows, credentials, settings |

`data/` and `n8n-data/` are gitignored. `.claude.json` is created automatically by `entrypoint.sh` on first start.

## Container internals

- Runs as user `clovis` (UID 1001). Host paths under `data/` must be owned by 1001.
- Claude Code is installed to `/usr/local/lib/node_modules/@anthropic-ai` with UID 1001 ownership so it can self-update.
- `tini` is PID 1 to reap Bun subprocesses spawned by the Telegram MCP server.
- `GITHUB_TOKEN` → git credential helper + `GH_TOKEN` for `gh` CLI (wired in `entrypoint.sh`).

## n8n — workflow integrations via MCP

n8n runs as a sidecar container and exposes integrations (Google, Waha, Todoist, etc.) as MCP servers that Claude picks up automatically.

**UI:** `http://localhost:5678` (accessible from the host browser)

**Adding an integration:**
1. Open n8n, create a new workflow, add an **MCP Server Trigger** as the first node
2. Add the service nodes (e.g. Google Sheets, Gmail) as tools under that trigger
3. Activate the workflow — n8n shows the MCP endpoint URL in the trigger node
4. Copy the URL, replace `localhost` with `n8n`: `http://n8n:5678/mcp/your-webhook-id`
5. Uncomment (or add) the matching line in `docker-compose.yml` under `agent.environment`, replacing the placeholder with the real webhook ID:
   ```yaml
   N8N_MCP_GMAIL: http://n8n:5678/mcp/your-gmail-webhook-id
   N8N_MCP_GCAL: http://n8n:5678/mcp/your-gcal-webhook-id
   ```
6. Restart the agent container: `docker compose restart agent`

Claude will log `entrypoint: registered MCP server 'n8n-google'` on startup when the var is active.

MCP URLs go in `docker-compose.yml` directly (not `.env`) — they contain no secrets and the `n8n` hostname only resolves inside the Docker network.

**Data:** persisted in `./n8n-data/` (gitignored, owned by UID 1000).

## Git conventions

- No Claude co-authorship in commits (`attribution.commit: ""` in `.claude/settings.json`).
- Always ask before `git push` — it is not auto-allowed.
- `settings.json` is committed (attribution only). Personal permission allows live in `settings.local.json` (gitignored).
