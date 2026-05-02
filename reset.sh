#!/usr/bin/env bash
set -euo pipefail

echo "This will stop the container and wipe all state in ./data/config and ./data/claude.json."
echo "The workspace (./data/workspace) will NOT be touched."
read -rp "Continue? [y/N] " confirm
if [ "${confirm}" != "y" ] && [ "${confirm}" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

# Stop the container if running
docker compose down 2>/dev/null || true

# Wipe auth, sessions, plugins, and wizard state
sudo rm -rf data/config data/claude.json

# Recreate with correct structure and permissions
mkdir -p data/config
touch data/claude.json
sudo chown -R 1001:1001 data/config data/claude.json

echo "Reset complete. Run ./setup.sh if you also need to reconfigure .env, or go straight to:"
echo "  docker compose run --rm claude-${BOT_NAME:-clovis}"
