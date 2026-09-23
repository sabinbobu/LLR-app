-- D1 database: llr-exercises (fc05b040-21c8-48b0-9b5a-33cdb2b6c7d9)
-- Applied by hand via the Cloudflare API; safe to re-run against a fresh database.

CREATE TABLE exercises (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  muscle_group TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_exercises_muscle_group ON exercises(muscle_group);
