-- Migration: add_deleted_records
-- Table pour propager les suppressions entre postes via Neon

CREATE TABLE IF NOT EXISTS "deleted_records" (
  "id"          INTEGER PRIMARY KEY AUTOINCREMENT,
  "table_name"  TEXT NOT NULL,
  "record_id"   INTEGER NOT NULL,
  "deleted_at"  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "deleted_by"  INTEGER
);

CREATE INDEX IF NOT EXISTS "idx_deleted_records_deleted_at"
  ON "deleted_records"("deleted_at");

CREATE INDEX IF NOT EXISTS "idx_deleted_records_table_deleted_at"
  ON "deleted_records"("table_name", "deleted_at");
