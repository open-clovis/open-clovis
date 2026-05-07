# Telegram setup

## Pair your account and lock down access

Open Telegram and send any message to your bot. It will reply with a pairing code.

Attach to the running container and open a Claude Code session:

```bash
docker compose run --rm agent
```

Once inside the Claude Code prompt (not your bash shell), run:

```
/telegram:access pair <code>
/telegram:access policy allowlist
```

The allowlist is critical: without it, anyone who finds your bot's username can send it messages and interact with your agent. Once enabled, only paired accounts are allowed — everyone else is silently dropped.

See the [Claude Code documentation](https://code.claude.com/docs/en/overview) for full details on how the sender allowlist works.

Exit with Ctrl+C. All state is saved to `./data/` and persists across restarts.
