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
| `entrypoint.sh` | Registers plugin marketplace, installs Telegram plugin, configures git credentials, starts `claude` |
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

n8n runs as a sidecar container and exposes integrations (Google, Waha, Todoist, etc.) as MCP servers.

**UI:** `http://localhost:5678` (accessible from the host browser)

**Data:** persisted in `./n8n-data/` (gitignored, owned by UID 1000).

### Creating a workflow in n8n

1. Open n8n, create a new workflow, add an **MCP Server Trigger** as the first node
2. Add service nodes (e.g. Google Sheets, Gmail) as tools under that trigger
3. Activate the workflow — n8n shows the MCP endpoint URL in the trigger node
4. Copy the URL and replace `localhost` with `n8n`: `http://n8n:5678/mcp/your-webhook-id`

### Registering the MCP in the workspace

MCPs are declared in `data/workspace/.mcp.json` (inside the container: `/home/clovis/workspace/.mcp.json`). Edit or create the file on the host:

```json
{
  "mcpServers": {
    "gmail": {
      "type": "http",
      "url": "http://n8n:5678/mcp/your-webhook-id"
    },
    "gcal": {
      "type": "http",
      "url": "http://n8n:5678/mcp/another-webhook-id"
    }
  }
}
```

Then restart the agent: `docker compose restart agent`.

> **Note:** The `n8n` hostname only resolves inside the Docker network — use it in `.mcp.json`, not `localhost`.

### Asking Claude to register an MCP

You can ask the Claude instance running in the container to do this for you via Telegram:

> "Add an MCP server called `gmail` pointing to `http://n8n:5678/mcp/<webhook-id>` in the workspace `.mcp.json`"

Claude will edit `workspace/.mcp.json` directly. The change takes effect after `/mcp reset` or a container restart.

## Waha — WhatsApp API

Waha runs as a sidecar container exposing a WhatsApp HTTP API on port 3000.

**UI / Swagger docs:** `http://localhost:3000` (accessible from the host browser)

**Data:** persisted in `./waha-data/` (gitignored).

**Authentication:** set `WAHA_API_KEY` in `.env` to require `X-Api-Key: <key>` on all API calls. Leave blank to disable auth (not recommended in production).

**Connecting WhatsApp:**
1. Open `http://localhost:3000`
2. Use the `/api/sessions` endpoint (or Swagger UI) to start a session
3. Fetch the QR code and scan it with your WhatsApp mobile app
4. The session persists in `./waha-data/` across restarts

## Git conventions

- No Claude co-authorship in commits (`attribution.commit: ""` in `.claude/settings.json`).
- Always ask before `git push` — it is not auto-allowed.
- `settings.json` is committed (attribution only). Personal permission allows live in `settings.local.json` (gitignored).
