FROM node:22-bookworm-slim

# Bun is required for the Telegram plugin MCP server
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates git tini unzip \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Install Bun system-wide
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash \
    && ln -sf /usr/local/bin/bun /usr/bin/bun

# Install gogcli (Google Workspace CLI for the agent)
# RUN set -eux; \
#     GOGCLI_VERSION="0.15.0"; \
#     ARCH="$(dpkg --print-architecture)"; \
#     curl -fsSL \
#       "https://github.com/openclaw/gogcli/releases/download/v${GOGCLI_VERSION}/gogcli_${GOGCLI_VERSION}_linux_${ARCH}.tar.gz" \
#       | tar -xz -C /usr/local/bin gog; \
#     chmod +x /usr/local/bin/gog

RUN npm install -g @anthropic-ai/claude-code

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /home/clovis/workspace

# tini reaps zombies; Bun spawns subprocesses for the Telegram plugin MCP server
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]