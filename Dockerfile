# Build openclaw from source (avoids npm packaging gaps).
FROM node:22-bookworm AS openclaw-build

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    python3 \
    make \
    g++ \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /openclaw

ARG OPENCLAW_GIT_REF=main
RUN git clone --depth 1 --branch "${OPENCLAW_GIT_REF}" https://github.com/openclaw/openclaw.git .

RUN set -eux; \
  find ./extensions -name 'package.json' -type f 2>/dev/null | while read -r f; do \
    sed -i -E 's/"openclaw"[[:space:]]*:[[:space:]]*">=[^"]+"/"openclaw": "*"/g' "$f"; \
    sed -i -E 's/"openclaw"[[:space:]]*:[[:space:]]*"workspace:[^"]+"/"openclaw": "*"/g' "$f"; \
  done || true

RUN pnpm install --no-frozen-lockfile
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:install && pnpm ui:build

# ---------------------------------------------------------------------------
# Runtime: code-server + tools + openclaw
# Build (context = clawdbot-ready so openclaw.json is found):
#   cd resources/scratch/clawdbot-ready && docker build -f Dockerfile.code-server -t claw-code-server .
# Or from repo root: docker build -f resources/scratch/clawdbot-ready/Dockerfile.code-server -t claw-code-server resources/scratch/clawdbot-ready
# ---------------------------------------------------------------------------
FROM codercom/code-server:latest

USER root

# Base: git, curl, jq, psql, ripgrep, gnupg (for gh keyring)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    gnupg \
    jq \
    postgresql-client \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN curl -sSfL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*

# Node 22 + npm (for npm, turbo)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

RUN npm install -g turbo @railway/cli

# OpenClaw: copy built tree + global wrapper
COPY --from=openclaw-build /openclaw /openclaw
RUN printf '%s\n' '#!/usr/bin/env bash' 'exec node /openclaw/dist/entry.js "$@"' > /usr/local/bin/openclaw \
    && chmod +x /usr/local/bin/openclaw

# Default OpenClaw state dir; copy config (build context = clawdbot-ready, so openclawd-config is here)
ENV OPENCLAW_STATE_DIR=/home/coder/.openclaw
RUN mkdir -p "${OPENCLAW_STATE_DIR}" && chown coder:coder "${OPENCLAW_STATE_DIR}"
COPY openclawd-config "${OPENCLAW_STATE_DIR}/"
RUN chown -R coder:coder "${OPENCLAW_STATE_DIR}"

# Verify
RUN gh --version && node -v && npm -v && turbo -V && railway -v && jq -V && rg --version && psql --version && openclaw --help

USER coder
