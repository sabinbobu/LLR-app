# LLR backend (Cloudflare)

Not used by the app yet — the iOS app is still fully local-first (SwiftData, bundled
`LLR/Resources/exercises.json`, zero network calls), per `CLAUDE.md`. This exists so a
future step (shared/synced exercise library, admin-maintained data, etc.) has a live
database and API to build against instead of starting from zero.

## What's live

- **D1 database**: `llr-exercises` (`fc05b040-21c8-48b0-9b5a-33cdb2b6c7d9`), account
  "Bobu Sabin Account" (`6342861f2a17ec22c03f13834db6ed45`). Schema in `schema.sql`.
  Seeded with all 451 rows from `LLR/Resources/exercises.json`.
- **Worker**: `llr-exercises-api`, source in `worker.js`, bound to the D1 database as `DB`.
  Live at `https://llr-exercises-api.bobu8sabin8.workers.dev`.

## Endpoints

- `GET /exercises` — all exercises, `[{id, name, muscle_group}, ...]`
- `GET /exercises?muscle=Chest` — filtered by muscle group

## Redeploying

Both were created directly via the Cloudflare API (no `wrangler.toml` yet). To manage
this with Wrangler instead:

```bash
cd Backend
npx wrangler d1 execute llr-exercises --remote --file=schema.sql   # if recreating the DB
npx wrangler deploy worker.js --name llr-exercises-api --compatibility-date 2026-09-17
```

Re-importing `LLR/Resources/exercises.json` after a schema reset is a one-off script,
not currently checked in — it was run ad hoc as `INSERT ... VALUES` batches of 40 rows
(D1 caps bound parameters per statement well under SQLite's own limit).
