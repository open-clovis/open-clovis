#!/usr/bin/env bash
set -euo pipefail

# Ask for bot name
read -rp "Bot name (e.g. jarbas): " bot_name
if [ -z "$bot_name" ]; then
  echo "Bot name cannot be empty." >&2
  exit 1
fi

# Bootstrap .env from example if not present
if [ ! -f .env ]; then
  cp .env.example .env
fi

# Generate a random keyring password if not already set
gog_pw=$(openssl rand -hex 32)
if grep -q '^GOG_KEYRING_PASSWORD=$' .env; then
  sed -i "s/^GOG_KEYRING_PASSWORD=.*/GOG_KEYRING_PASSWORD=${gog_pw}/" .env
fi

# Write bot name into .env
if grep -q '^BOT_NAME=' .env; then
  sed -i "s/^BOT_NAME=.*/BOT_NAME=${bot_name}/" .env
else
  echo "BOT_NAME=${bot_name}" >> .env
fi

# Prompt for Telegram bot token
read -rp "Telegram bot token (from @BotFather, leave blank to set later): " telegram_token
if [ -n "$telegram_token" ]; then
  if grep -q '^TELEGRAM_BOT_TOKEN=' .env; then
    sed -i "s/^TELEGRAM_BOT_TOKEN=.*/TELEGRAM_BOT_TOKEN=${telegram_token}/" .env
  else
    echo "TELEGRAM_BOT_TOKEN=${telegram_token}" >> .env
  fi
fi

echo ""
echo "Setup complete."

read -rp "Build the Docker image now? [Y/n] " build_now
build_now="${build_now:-Y}"
if [[ "$build_now" =~ ^[Yy]$ ]]; then
  docker compose build
  echo ""
  echo "Build done. Run the first-time wizard with:"
  echo "  docker compose run --rm agent"
else
  echo ""
  echo "When ready, run:"
  echo "  docker compose build"
  echo "  docker compose run --rm agent"
fi
