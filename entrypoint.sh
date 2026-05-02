#!/bin/sh
set -e

if [ -n "${GITHUB_TOKEN:-}" ]; then
  git config --global credential.helper \
    '!f() { echo "username=x-token"; echo "password='"$GITHUB_TOKEN"'"; }; f'
fi

exec claude --channels plugin:telegram@claude-plugins-official
