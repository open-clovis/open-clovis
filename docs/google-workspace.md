# Google Workspace (Gmail, Calendar)

The image ships [workspace-mcp](https://github.com/taylorwilsdon/google_workspace_mcp) — a Google Workspace MCP server covering Gmail, Calendar, Drive, and more. It starts automatically on port 8000 when OAuth credentials are provided.

## 1. Create an OAuth client in Google Cloud Console

1. Go to [console.cloud.google.com](https://console.cloud.google.com/) and create or reuse a project.
2. Enable the APIs you need: [Gmail API](https://console.cloud.google.com/apis/library/gmail.googleapis.com), [Calendar API](https://console.cloud.google.com/apis/library/calendar-json.googleapis.com).
3. Go to **APIs & Services → OAuth consent screen**: choose **External**, fill in the app name and your email, add the scopes you enabled, then add your Gmail address as a test user.
4. Go to **APIs & Services → Credentials → Create Credentials → OAuth client ID**: choose **Web application**, add `http://localhost:8000/oauth2callback` as an Authorized redirect URI.
5. Copy the **Client ID** and **Client Secret**.

## 2. Add credentials to `.env`

```env
GOOGLE_OAUTH_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_SECRET=GOCSPX-...
```

## 3. Restart the container

```bash
docker compose down && docker compose up -d
```

The entrypoint starts `workspace-mcp` in the background on port 8000 (bound to `127.0.0.1` only via `docker-compose.yml`).

## 4. Complete the one-time OAuth flow

On first start, open `http://localhost:8000` in your browser. You will be redirected to Google's consent screen. After authorizing, the token is cached and reused on every subsequent start.

## Workspace configuration

The MCP server is pre-configured in `workspace/.mcp.json`:

```json
{
  "mcpServers": {
    "gmail": { "type": "http", "url": "http://localhost:8000/mcp" }
  }
}
```

Claude Code connects to it automatically. Once authorized, you can ask Claude to read emails, manage calendar events, etc.
