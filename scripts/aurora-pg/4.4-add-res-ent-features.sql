-- 4.4-add-res-ent-features.sql
-- Enable the Senzing 4.4 "features on RES_ENT" capability by adding a FEATURES column to
-- RES_ENT so the 4.4 engine populates/uses it during resolution.
--
-- ⚠️ TIMING: run this AFTER the Senzing schema is initialized (RES_ENT exists — i.e. after
--    the stack's init/config task has run) and BEFORE any records are loaded (before the
--    consumers start). Records resolved before the column exists won't carry FEATURES.
--
-- Idempotent: IF NOT EXISTS makes it safe to re-run and safe if a future 4.4.x schema
-- already ships the column.
--
-- Usage (on the sshd host, once the schema exists):
--   $PG -f /tmp/4.4-add-res-ent-features.sql

\echo '--- adding RES_ENT.FEATURES (4.4 feature) ---'
ALTER TABLE RES_ENT ADD COLUMN IF NOT EXISTS FEATURES TEXT;

\echo '--- verify the column now exists (expect one row: features | text) ---'
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'res_ent' AND column_name = 'features';
