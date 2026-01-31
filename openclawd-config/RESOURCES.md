# RESOURCES — Momentum Bets (mb-stack)

Where to look when answering questions. **Mission:** See **MISSION.md** for what Momentum Bets is and the bot’s goal (maintenance, observability, chat for infra/observability, investigations, action items). **Worktree-first:** mb-stack is developed with git worktrees; `MB_STACK_ROOT` = main worktree path (canonical root for docs). Paths below are relative to whichever worktree is in use. **Postgres read-only:** See **POSTGRES_READONLY.md** for TimescaleDB-safe, efficient query rules.

## Primary docs (in repo)

| Doc | Path | Use for |
|-----|------|--------|
| Agent guide | `AGENTS.md` | Commands, critical rules, topic index |
| Quick ref | `CLAUDE.md` | TimescaleDB, imports, pre-commit, ports |
| Architecture | `docs/agents/architecture.md` | Imports, modules, services |
| Database | `docs/agents/database.md` | TimescaleDB, schema, migrations |
| Deployment | `docs/agents/deployment.md` | Railway, env vars, prod URLs |
| Reference | `docs/agents/reference.md` | Ports, lib paths, config files |
| Testing | `docs/agents/testing.md` | E2E, unit, test users |
| TypeScript | `docs/agents/typescript.md` | Linting, type-check |
| Features | `docs/agents/features.md` | Auth, jobs, observability |

## Deeper docs

- `docs/architecture/README.md` — system design
- `docs/database/README.md` — schema, TimescaleDB
- `docs/testing/README.md` — test strategy
- `docs/monitoring/README.md` — observability
- `docs/tech/README.md` — tech stack

## Key paths in repo

- **Apps:** `apps/client`, `apps/server`, `apps/odds-ingestion`, `apps/criteria-evaluator`, `apps/sports-scanner`, `apps/notification-service`, `apps/stripe-webhooks`
- **Libs:** `libs/db`, `libs/types`, `libs/utils`, `libs/ui`, `libs/auth`, `libs/server-common`
- **Config:** `turbo.json`, `tsconfig.base.json`, `drizzle.config.ts`, `jest.config.ts`

## Production URLs

- App: https://app.momentumbets.com
- Admin: https://app.momentumbets.com/admin
- Grafana: https://grafana.momentumbets.com

## Service ports (local dev)

| Service | Port |
|---------|------|
| client | 3000 |
| server | 3001 |
| odds-ingestion | 3002 |
| criteria-evaluator | 3003 |
| sports-scanner | 3004 |
| notification-service | 3005 |
| stripe-webhooks | 3010 |


# Postgres (read-only) — efficient queries for Clawdbot

Use **only** `DATABASE_READONLY_URL` for Postgres. Never use the write URL (`DATABASE_URL`). You have a read-only user: **SELECT only**. No INSERT, UPDATE, DELETE, DDL, or CREATE.

---

## TimescaleDB rules (mandatory)

The DB uses **TimescaleDB**. Hypertables have partition key columns. Using `NOW()` or `CURRENT_TIMESTAMP` in WHERE on those columns causes **ERROR: could not open relation with OID 0**. Always follow these rules.

### Hypertables and partition keys

- **mb_sport_event_odds_snapshot** — partition key: `oo_timestamp`
- **mb_user_criteria_eval_trace** — partition key: `created_at`

### ❌ WRONG — do not use

```sql
-- FAILS on hypertables
SELECT * FROM mb_user_criteria_eval_trace
WHERE created_at >= NOW() - INTERVAL '1 hour';

SELECT * FROM mb_sport_event_odds_snapshot
WHERE oo_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1 day';
```

### ✅ CORRECT — use helper functions

Use these **instead of** `NOW()`, `CURRENT_TIMESTAMP`, `CURRENT_DATE` on partition key columns:

- **ts_now()** — use instead of `NOW()`
- **ts_current_timestamp()** — use instead of `CURRENT_TIMESTAMP`
- **ts_current_date()** — use instead of `CURRENT_DATE`
- **ts_interval_ago('1 hour')** — timestamp from interval ago (best for time ranges)

```sql
-- OK: time range on partition key
SELECT * FROM mb_user_criteria_eval_trace
WHERE created_at >= ts_interval_ago('1 hour')
LIMIT 100;

-- OK: ts_now() for “now”
SELECT * FROM mb_user_criteria_eval_trace
WHERE created_at >= ts_now() - INTERVAL '1 hour'
LIMIT 100;

-- OK: time range on odds snapshot
SELECT * FROM mb_sport_event_odds_snapshot
WHERE oo_timestamp >= ts_interval_ago('1 day')
LIMIT 100;
```

---

## Efficient read-only habits

1. **Always add a time range** on partition key columns when querying hypertables — enables chunk pruning and avoids full scans.
2. **Use LIMIT** (e.g. 100, 1000) so queries stay bounded.
3. **Prefer ts_interval_ago('…')** for “last N hours/days” on partition columns.
4. **Non-partition columns** (e.g. `started_at`, `completed_at` on other tables) can use `NOW()`; the restriction is only on hypertable partition key columns.

---

## Using psql

- Connect with the read-only URL only:  
  `psql "$DATABASE_READONLY_URL"`  
  (or pass the URL as the first argument to `psql`).
- Run only **SELECT**; never run INSERT/UPDATE/DELETE or DDL.
- For ad-hoc exploration, keep queries small (WHERE + LIMIT).

---

## Reference in repo

- **docs/agents/database.md** — TimescaleDB rules, helper functions, Drizzle usage
- **docs/database/README.md** — schema overview, table list
- **docs/database/schema.md** — full schema reference
