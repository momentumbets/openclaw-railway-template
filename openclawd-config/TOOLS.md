# TOOLS — Integrations & Allowlist

Use these to help with debugging, CI, deployment, and codebase questions. Destructive or write actions (create issue/PR, deploy, migrate) require explicit approval unless in allowlist. **Goal:** Reduce maintenance and manual work; be the chat interface for infra and observability; run investigations and highlight issues/action items. See **MISSION.md** for full capabilities.

---

## Capabilities & Workflows

### Automated or assisted PRs for fixes

- **When allowlist includes write:** Use `gh pr create`, `gh issue create`, `git push` to open branches and PRs for fixes (e.g. from Sentry or logs). Always run `npm run fix` and type-check before opening a PR.
- **When write not allowed:** Investigate → suggest exact file + change → human creates PR; or draft PR description and diff for human to run.

### Sentry & Grafana investigation + fix suggestions

- **Sentry:** GET issues/events (read-only API). Map stack trace and context to mb-stack paths (e.g. `apps/server/...`, `libs/...`). Output: what failed, **where to fix** (file/module), and a short recommendation.
- **Grafana:** Use dashboards/query API to explain errors or latency. Suggest which service/component and where in the repo to fix or add instrumentation.

### User activity executive summary

- **Source:** Postgres read-only (`DATABASE_READONLY_URL`). Follow **RESOURCES.md** / **POSTGRES_READONLY.md** (TimescaleDB: use `ts_interval_ago()`, never `NOW()` on partition keys).
- **Deliver:** Executive summary for last day and last week: new users, logins (count + distinct users), criteria count (and new/updated), evaluations count and outcomes. Use time-bounded queries and LIMIT.

### Proactive feature ideas & implementation

- Suggest features from usage (e.g. activity summaries, support themes). Help with specs/PRDs (see repo `docs/`) and implementation (tasks, file changes, draft code/PRs; use approval for writes if not in allowlist).

---

## Repo (Momentum Bets / mb-stack) — worktree-first

- **Primary workflow:** mb-stack is developed with **git worktrees** (one main clone, separate worktrees per branch). Prefer suggesting `git worktree add <path> <branch>` for new branches; run commands in the relevant worktree.
- **Root:** Set `MB_STACK_ROOT` to the **main worktree path** (canonical repo root for docs/paths). If the bot is in a worktree, that path is the current context.
- **Worktree commands (allowlisted):**
  - `git worktree list` — list all worktrees
  - `git worktree add <path> <branch>` — create worktree for branch (e.g. `git worktree add ../mb-stack-feature feature-branch`)
  - `git worktree prune` — remove stale worktree refs
  - `git worktree remove <path>` — remove a worktree
- **New worktree setup** (remind after creating): `npm i` then `npm run dev`. Full setup if needed: `npm i`, `npm run setup:dev`, `npm run dev`.
- **Key docs:** `AGENTS.md`, `CLAUDE.md`, `docs/agents/*`, `docs/database/README.md`, `docs/architecture/README.md`, `docs/monitoring/README.md`
- **Essential commands:**
  - `npm run dev` — start all services
  - `npm run fix` — lint/format (run before commits)
  - `npm run build` — build all
  - `turbo run type-check` — type check
  - `npm run test:unit` — unit tests
  - `npm run db:migrate` — run migrations

---

## GitHub (gh CLI)

- Repo: set via `GH_REPO` or use `gh repo view` to confirm.
- **Read-only (allowlist):** `gh issue list`, `gh issue view`, `gh pr list`, `gh pr view`, `gh run list`, `gh run view`, `gh workflow list`, `gh repo view`
- **Write (approval unless in allowlist):** `gh issue create`, `gh pr create`, `gh pr merge`, comments. To enable **automated PRs** for fixes (e.g. from Sentry/logs), add `gh issue create*`, `gh pr create*`, and `git push*` to the exec allowlist in config (see config.yaml).

---

## Grafana, OTEL, logs

- **Grafana URL:** https://grafana.momentumbets.com
- **Auth:** `Authorization: Bearer $GRAFANA_API_KEY`
- **Read-only:** Dashboards, search, query API. Example:
  - `curl -s -H "Authorization: Bearer $GRAFANA_API_KEY" "https://grafana.momentumbets.com/api/search"`
- **OTEL/traces:** If the stack exposes OTLP or trace endpoints (see deployment/observability docs), use read-only access for investigations.
- **Logs:** Railway service logs, Docker logs, or app log endpoints (read-only) for debugging and investigation.

---

## Sentry (read-only only)

- **Project:** momentum-prod (or org/project from Sentry config).
- **Auth:** `Authorization: Bearer $SENTRY_AUTH_TOKEN`
- **Safe usage:** Use **only read-only API (GET)**. Never use write/delete endpoints. List issues, view event details, search. Example:
  - `curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" "https://sentry.io/api/0/projects/{org}/{project}/issues/"`

---

## Postgres (read-only only)

- **Connection:** Use **only** `DATABASE_READONLY_URL` (read-only user). Never use `DATABASE_URL` (write).
- **Allowed:** SELECT only. No INSERT, UPDATE, DELETE, DDL, or CREATE.
- **TimescaleDB:** Hypertables require special handling. **Read POSTGRES_READONLY.md** before writing any SQL: use `ts_interval_ago()`, `ts_now()` on partition key columns; never use `NOW()` in WHERE on hypertables. Always add time ranges and LIMIT for efficient queries.
- **psql:** `psql "$DATABASE_READONLY_URL"` then run SELECT only.

---

## Railway

- **Docs:** https://docs.railway.app/reference/public-api
- **Auth:** `Authorization: Bearer $RAILWAY_API_TOKEN`
- **Hostnames:** Config has a `services` section (app, admin, grafana, postgres_ui). Fill per-service URLs from Railway dashboard or `railway link` then `railway status`.
- **Read-only:** Deployment status, logs, project info. Write (deploy, env changes) requires approval.

---

## Exec allowlist (for config)

Commands that can run without approval (read-only / safe):

```yaml
allowlist:
  # GitHub (read-only)
  - "gh issue list*"
  - "gh issue view*"
  - "gh pr list*"
  - "gh pr view*"
  - "gh pr checks*"
  - "gh pr diff*"
  - "gh run list*"
  - "gh run view*"
  - "gh run download*"
  - "gh run watch*"
  - "gh workflow list*"
  - "gh workflow view*"
  - "gh repo view*"
  - "gh repo clone*"
  - "gh release list*"
  - "gh release view*"
  - "gh commit view*"
  - "gh search*"
  - "gh label list*"
  - "gh milestone list*"
  - "gh milestone view*"
  - "gh gist list*"
  - "gh gist view*"
  - "gh auth status*"
  - "gh api get*"
  # HTTP (read-only)
  - "curl*https://grafana.momentumbets.com*"
  - "curl*https://sentry.io*"
  - "curl*api.railway.app*"
  - "curl*https://app.momentumbets.com*"
  # Repo / codebase
  - "cat *"
  - "ls *"
  - "head *"
  - "tail *"
  - "wc *"
  - "grep *"
  - "rg *"
  # Git (read-only + worktrees)
  - "git status*"
  - "git log*"
  - "git show*"
  - "git diff*"
  - "git branch*"
  - "git worktree list*"
  - "git worktree add*"
  - "git worktree prune*"
  - "git worktree remove*"
  # NPM / Turbo (any command)
  - "npm *"
  - "npx *"
  - "turbo *"
  # JSON / inspection
  - "jq *"
  # Railway CLI (read-only)
  - "railway status*"
  - "railway logs*"
  # Docker (read-only)
  - "docker ps*"
  - "docker logs*"
  # Postgres (read-only only — use DATABASE_READONLY_URL; see POSTGRES_READONLY.md)
  - "psql *"
```

Anything else (e.g. `gh pr create`, deploys, git push) — ask first.
