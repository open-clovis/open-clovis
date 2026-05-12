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

# gogcli: register OAuth client if a Google OAuth JSON was dropped into the workspace root
# for _gog_client in "${HOME}"/client_secret_*.json; do
#   [ -f "$_gog_client" ] || break
#   gog auth credentials "$_gog_client" || true
#   rm -f "$_gog_client"
# done

# gogcli: warn if account token is missing (one-time interactive step)
# if [ -n "${GOG_GOOGLE_ACCOUNT:-}" ]; then
#   if ! gog auth list 2>/dev/null | grep -qF "${GOG_GOOGLE_ACCOUNT}"; then
#     echo ""
#     echo "gogcli: no token found for ${GOG_GOOGLE_ACCOUNT}."
#     echo "Run once to authorize (visit the printed URL, then paste the redirect URL back):"
#     echo "  docker compose run --rm agent gog auth add ${GOG_GOOGLE_ACCOUNT} --services gmail,calendar,drive --manual"
#     echo ""
#   fi
# fi

exec claude --channels plugin:telegram@claude-plugins-official
