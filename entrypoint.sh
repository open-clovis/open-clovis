#!/bin/sh
set -e

# Pre-accept the workspace trust dialog so Claude doesn't hang waiting for input
CLAUDE_JSON="${HOME}/.claude.json"
[ -d "$CLAUDE_JSON" ] && rm -rf "$CLAUDE_JSON"
[ -f "$CLAUDE_JSON" ] || echo '{}' > "$CLAUDE_JSON"
node -e "
  const fs = require('fs'), f = process.env.HOME + '/.claude.json';
  const d = JSON.parse(fs.readFileSync(f, 'utf8'));
  d.projects = d.projects || {};
  d.projects['/home/clovis/workspace'] = d.projects['/home/clovis/workspace'] || {};
  d.projects['/home/clovis/workspace'].hasTrustDialogAccepted = true;
  fs.writeFileSync(f, JSON.stringify(d));
"

if [ -n "${GITHUB_TOKEN:-}" ]; then
  git config --global credential.helper \
    '!f() { echo "username=x-token"; echo "password='"$GITHUB_TOKEN"'"; }; f'
  export GH_TOKEN="$GITHUB_TOKEN"
fi

# Telegram plugin — install once, skip forever after
# Sentinel lives inside the channels dir so wiping channels/ triggers a clean reinstall.
_TELEGRAM_SENTINEL="${HOME}/.claude/channels/telegram/.installed"
_TELEGRAM_PLUGIN_DIR="${HOME}/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/telegram"

# Google Workspace MCP — start as a background HTTP sidecar when credentials are present
if [ -n "${GOOGLE_OAUTH_CLIENT_ID:-}" ] && [ -n "${GOOGLE_OAUTH_CLIENT_SECRET:-}" ]; then
  echo "entrypoint: starting google_workspace_mcp on port 8000"
  GOOGLE_OAUTH_CLIENT_ID="$GOOGLE_OAUTH_CLIENT_ID" \
  GOOGLE_OAUTH_CLIENT_SECRET="$GOOGLE_OAUTH_CLIENT_SECRET" \
  WORKSPACE_MCP_STATELESS_MODE=true \
  uvx workspace-mcp --transport streamable-http --port 8000 &
  _GOOGLE_MCP_PID=$!
  echo "entrypoint: google_workspace_mcp pid=$_GOOGLE_MCP_PID"
fi

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
  if [ ! -f "$_TELEGRAM_SENTINEL" ] || [ ! -d "$_TELEGRAM_PLUGIN_DIR" ]; then
    echo "entrypoint: first run — installing Telegram plugin"
    claude plugins install telegram@claude-plugins-official || true
    mkdir -p "${HOME}/.claude/channels/telegram"
    touch "$_TELEGRAM_SENTINEL"
    echo "entrypoint: Telegram plugin installed"
  else
    echo "entrypoint: Telegram plugin already installed, skipping"
  fi
  exec claude --channels plugin:telegram@claude-plugins-official
else
  exec claude
fi
