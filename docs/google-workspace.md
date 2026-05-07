# Google Workspace (gogcli) — experimental

The image ships [gogcli](https://gogcli.sh/) — a single binary covering Gmail, Calendar, Drive, Docs, Sheets, and more. It is opt-in: no credentials are required to run the agent.

To enable it, complete a one-time auth setup:

## 1. Create an OAuth client in Google Cloud Console

1. Go to [console.cloud.google.com](https://console.cloud.google.com/) and create a new project (or reuse one).
2. Enable the APIs you want — e.g. [Gmail API](https://console.cloud.google.com/apis/library/gmail.googleapis.com), [Google Calendar API](https://console.cloud.google.com/apis/library/calendar-json.googleapis.com), [Google Drive API](https://console.cloud.google.com/apis/library/drive.googleapis.com).
3. Go to **APIs & Services → OAuth consent screen**: choose **External**, fill in the app name and your email, add the scopes you enabled, then add your Gmail address as a test user.
4. Go to **APIs & Services → Credentials → Create Credentials → OAuth client ID**: choose **Desktop app**, name it, and click **Create**.
5. Click **Download JSON** — you'll get a file named `client_secret_<id>.json`. Keep it private.

## 2. Drop the client JSON into the workspace and set your email

```bash
cp client_secret_*.json ./data/workspace/
```

Add to `.env`:

```env
GOG_KEYRING_PASSWORD=some-random-secret
GOG_GOOGLE_ACCOUNT=you@gmail.com
```

On next start, `entrypoint.sh` registers the credentials automatically and deletes the file.

## 3. Complete the one-time account OAuth

The entrypoint will print this if no token exists yet:

```
gogcli: no token found for you@gmail.com.
Run once to authorize (visit the printed URL, then paste the redirect URL back):
  docker compose run --rm agent gog auth add you@gmail.com --services gmail,calendar,drive --manual
```

Run that command, open the printed URL in your browser, and authorize the app. The browser will redirect to `http://127.0.0.1:...` — that page won't load, which is expected. Copy the full URL from the address bar and paste it into the terminal when prompted. The encrypted refresh token is saved to `./data/workspace/.config/gogcli/` and persists across restarts.
