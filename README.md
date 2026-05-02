# claude-clovis-template

A template for running [Claude Code](https://claude.ai/code) as a persistent, Telegram-connected Docker agent. Fork this repo once per agent — each fork becomes an independent instance with its own name, Telegram bot, workspace, and configuration.

```
thiagob/claude-clovis-template   ← this repo (template, don't run directly)
       ↓ fork          ↓ fork
thiagob/claude-jarbas  thiagob/claude-eve   ← one repo per agent
```

## How it works

The container installs Claude Code and starts it with the `--channels` flag, loading the official Telegram plugin (`plugin:telegram@claude-plugins-official`). [Bun](https://bun.sh) is required by the channels MCP server and is installed system-wide. [tini](https://github.com/krallin/tini) is used as PID 1 to reap zombie processes that Bun spawns.

> **Note:** The Telegram channels feature requires a compatible Claude plan (Pro, Max, Team, or Enterprise).

## Creating a new agent

### 1. Fork this template

Click **Use this template** on GitHub, name the new repo after your agent (e.g. `claude-jarbas`), then clone it:

```bash
git clone https://github.com/thiagob/claude-jarbas.git
cd claude-jarbas
```

### 2. Run setup

```bash
./setup.sh
```

The script will ask for the bot name, create the required directories and files, set correct permissions, and generate a `.env` from the example.

### 3. Fill in `.env`

```env
BOT_NAME=jarbas
TODOIST_API_TOKEN=your-todoist-token
CLAUDE_CODE_OAUTH_TOKEN="your-claude-oauth-token"
```

To get a long-lived OAuth token, run on a machine where you are already logged into Claude Code:

```bash
claude setup-token
```

> Always wrap `CLAUDE_CODE_OAUTH_TOKEN` in double quotes — the token may contain a `#` which `.env` parsers treat as a comment delimiter, silently truncating the value.

### 4. Build and run the first-time wizard

```bash
docker compose build
docker compose run --rm claude-<botname>
```

On first start Claude Code will:
1. Ask you to select a login method — choose **Claude account with subscription**
2. Show a URL to complete OAuth in your browser
3. Show a theme/onboarding wizard — complete it fully before exiting

Once inside, install and configure the Telegram plugin:

```
/plugin install telegram@claude-plugins-official
/telegram:configure <your-botfather-token>
```

Exit with Ctrl+C. All state is saved to `./data/` and persists across restarts.

### 5. Run in the background

```bash
docker compose up -d
```

Open Telegram and message your bot. Claude Code will respond as if you were using it in a terminal.

## Configuration

| Variable | Required | Description |
|---|---|---|
| `BOT_NAME` | Yes | Agent name — sets the Docker container name to `claude-<name>` |
| `CLAUDE_CODE_OAUTH_TOKEN` | Yes | Long-lived auth token from `claude setup-token` |
| `TODOIST_API_TOKEN` | No | Todoist integration token |
| `TZ` | No | Container timezone. Defaults to `America/Sao_Paulo` |

### Volumes

| Host path | Container path | Purpose |
|---|---|---|
| `./data/config` | `/home/claude/.claude` | OAuth tokens, Telegram pairing, sessions, plugins |
| `./data/claude.json` | `/home/claude/.claude.json` | Wizard state, theme preference |
| `./data/workspace` | `/workspace` | Files Claude reads and writes |

> `./data/claude.json` must exist as a **file** before the first run — the setup script handles this. If Docker created it as a directory, remove it and re-run `setup.sh`.

## Commands

```bash
docker compose logs -f     # follow logs
docker compose down        # stop (state preserved in ./data/)
docker compose up -d       # restart
```
