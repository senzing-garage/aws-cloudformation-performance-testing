-- =============================================================================
-- final-capture.sql  —  EXACT end-of-run counts + throughput/erpm for the
-- report. Run ONCE, only after the load is VERIFIED complete (see the runbook
-- drain gate / drain-check.sql) and AFTER the IO-metrics harness has taken its
-- 20-final.sql snapshot, so these full scans land OUTSIDE the measured window.
--
-- Why fast now (was pathological during the load):
--   1. Writers stopped -> no xmin pinned, no dead-tuple pile-up.
--   2. We force a plain HEAP SEQ SCAN for count(*) (below), whose cost is
--      independent of visibility-map freshness — so it completes in bounded
--      sequential-read time even if VACUUM was skipped or the VM is stale.
--   3. VACUUM (ANALYZE) first strips sys_eval_queue delete-storm bloat and
--      makes reltuples honest; it is NOT what makes the counts correct/fast.
--
-- OWNERSHIP: the Aurora master user is rds_superuser but does NOT own Senzing's
-- tables, so VACUUM would silently WARNING-and-skip (ON_ERROR_STOP does not trip
-- on a WARNING). Step 0a hard-asserts ownership so a skipped VACUUM can never
-- masquerade as a completed one. Run as the Senzing table owner (or a role in
-- pg_maintain), NOT the bare master user. If you cannot, comment out Steps 0a+0b
-- — with the index paths disabled in Step 1 the counts are still exact and fast.
-- =============================================================================
\set ON_ERROR_STOP on
\timing on

-- --- Step 0a: OWNERSHIP ASSERTION (hard error, respects ON_ERROR_STOP) --------
DO $$
DECLARE
    bad text;
BEGIN
    SELECT string_agg(c.relname, ', ')
      INTO bad
      FROM pg_class c
     WHERE c.relname IN ('dsrc_record','obs_ent','res_ent','res_ent_okey',
                         'sys_eval_queue','res_relate')
       AND NOT ( pg_has_role(current_user, c.relowner, 'USAGE')
                 OR pg_has_role(current_user, 'pg_maintain', 'USAGE') );
    IF bad IS NOT NULL THEN
        RAISE EXCEPTION
          'final-capture aborted: current_user (%) cannot VACUUM: % — run as the Senzing table owner or a role in pg_maintain so VACUUM is not silently skipped (or comment out Steps 0a+0b).',
          current_user, bad;
    END IF;
END $$;

-- --- Step 0b: strip dead-tuple bloat + refresh reltuples ----------------------
-- VACUUM cannot run inside a transaction block -> top-level autocommit, one per
-- line. sys_eval_queue (delete-storm churn) needs it most; on ~7M dead tuples
-- this pass can take minutes (bounded, completing).
VACUUM (ANALYZE) sys_eval_queue;
VACUUM (ANALYZE) dsrc_record;
VACUUM (ANALYZE) obs_ent;
VACUUM (ANALYZE) res_ent;
VACUUM (ANALYZE) res_ent_okey;
VACUUM (ANALYZE) res_relate;

-- --- Step 1: FORCE a plain heap seq scan for count(*) in THIS session ----------
-- enable_seqscan=on ALONE does NOT force a seq scan — it only lifts the
-- disable_cost penalty; an index-only scan over a fresh VM can still win.
-- Disabling the index paths too makes a heap seq scan the ONLY surviving plan,
-- so count(*) is bounded regardless of VM state. USERSET GUCs: per-session SET
-- overrides the param-group enable_seqscan=0 and does not affect Senzing OLTP.
SET enable_seqscan       = on;
SET enable_indexonlyscan = off;
SET enable_indexscan     = off;
SET enable_bitmapscan    = off;

-- Each count is its own short statement (never one monolithic six-subquery one).
SELECT now() AS at, 'dsrc_record'    AS relname, count(*) AS exact_rows FROM dsrc_record;
SELECT now() AS at, 'obs_ent'        AS relname, count(*) AS exact_rows FROM obs_ent;
SELECT now() AS at, 'res_ent'        AS relname, count(*) AS exact_rows FROM res_ent;
SELECT now() AS at, 'res_ent_okey'   AS relname, count(*) AS exact_rows FROM res_ent_okey;
SELECT now() AS at, 'sys_eval_queue' AS relname, count(*) AS exact_rows FROM sys_eval_queue;  -- expect ~0
SELECT now() AS at, 'res_relate'     AS relname, count(*) AS exact_rows FROM res_relate;
-- res_ent_active: 4.x has res_ent.ent_state; the 3.x g2 schema differs and errors on this
-- predicate. Run it DYNAMICALLY (no parse-time column resolution) and degrade to n/a on
-- any error, so a schema mismatch can't abort the rest of the capture (it did on 3.13.1,
-- which cost us the erpm/throughput line below).
DO $$
DECLARE n bigint;
BEGIN
  EXECUTE 'SELECT count(*) FROM res_ent WHERE ent_state <> 0' INTO n;
  RAISE NOTICE 'res_ent_active exact_rows = %', n;
EXCEPTION WHEN others THEN
  RAISE NOTICE 'res_ent_active = n/a (not available on this schema: % %)', SQLSTATE, SQLERRM;
END $$;

-- --- Step 2: overall throughput / entity-resolutions per minute ---------------
SELECT
    min(first_seen_dt)                                           AS load_start,
    max(first_seen_dt)                                           AS load_end,
    max(first_seen_dt) - min(first_seen_dt)                      AS duration,
    count(*)                                                     AS total,
    count(*) / (extract(EPOCH FROM (max(first_seen_dt) - min(first_seen_dt))) / 60)        AS erpm,
    (count(*) / (extract(EPOCH FROM (max(first_seen_dt) - min(first_seen_dt))) / 60)) / 60 AS avg_erps
FROM dsrc_record;

-- --- Restore planner defaults for this session --------------------------------
RESET enable_seqscan;
RESET enable_indexonlyscan;
RESET enable_indexscan;
RESET enable_bitmapscan;
