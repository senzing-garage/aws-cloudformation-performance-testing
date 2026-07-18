-- unresolved-forensics.sql
-- Isolate what happened to records that reached OBS_ENT but never resolved
-- (present in OBS_ENT, absent from RES_ENT_OKEY -> no RES_ENT).
--
-- WHY THE DB, NOT CLOUDWATCH: Senzing logs errors, not per-record successes, and
-- error lines key off internal ids / the advisory-lock KEY (the $1 in
-- "SELECT pg_advisory_lock($1)"), not the DSRC RECORD_ID or OBS_ENT_ID. A
-- silently-unresolved record leaves no matchable log line, so the DB is the
-- ground truth for reconstructing its state.
--
-- Read-only (SELECTs + one TEMP table). Safe on a live or post-run DB.
-- Usage:  PGPASSWORD=... psql -h <writer-host> -U senzing -d G2 -f /tmp/unresolved-forensics.sql
--
-- The OBS_ENT_IDs below are the 40 from the 20260715 100M v4.4 run -- replace as needed.

\timing on

-- 0. CONFIRM COLUMN NAMES first (the schema drifts across Senzing versions; the
--    queries below assume the columns seen in this run's DDL).
\echo ===== schema of the tables this script touches =====
\d obs_ent
\d res_ent_okey
\d res_ent
\d sys_eval_queue

-- 1. The suspects: COMPUTED from the CURRENT database (observed-but-unresolved =
--    in OBS_ENT, absent from RES_ENT_OKEY). No hardcoded id list -- it can't go
--    stale between runs (obs_ent_id is a per-run sequence; a list from another run
--    probes different records). This is the same anti-join as validate.sql query 1.
--    The DB is quiet post-drain, so the 100M-vs-100M index anti-join is cheap even
--    under enable_seqscan=0.
DROP TABLE IF EXISTS _unresolved;
CREATE TEMP TABLE _unresolved AS
  SELECT o.obs_ent_id
  FROM obs_ent o
  LEFT JOIN res_ent_okey k ON k.obs_ent_id = o.obs_ent_id
  WHERE k.obs_ent_id IS NULL;
CREATE UNIQUE INDEX ON _unresolved (obs_ent_id);
\echo ===== unresolved count (should match obs_ent - res_ent_okey) =====
SELECT count(*) AS unresolved_count FROM _unresolved;

-- 2. HOW FAR DID EACH GET? (columns confirmed via \d on this run:
--    OBS_ENT: obs_ent_id, locking_id, last_touch_dt, dsrc_id, ent_src_key, features)
--    NB: last_touch_dt is a bigint of EPOCH MILLISECONDS -> to_timestamp(x/1000.0).
--    - last_touch_utc   : when resolution last ran (correlate to the log spikes)
--    - locking_id       : if non-zero, a lock was held -- a timeout abort may have
--                         left it stranded (observed 0 for all 40 = no stranded lock)
--    - features_present : did feature extraction finish before it stalled?
--                         (observed t for all 40 = extracted, then never persisted)
--    - has_res_ent_okey : the "resolved" flag -- expect f for all
\echo ===== per-record state =====
SELECT
    u.obs_ent_id,
    r.record_id,
    o.last_touch_dt AS last_touch_raw,   -- NB: 4.3.3 may store 0 (epoch) -> clustering below is moot if so
    to_timestamp(NULLIF(o.last_touch_dt,0) / 1000.0) AT TIME ZONE 'UTC' AS last_touch_utc,
    o.locking_id,
    (o.features IS NOT NULL) AS features_present,
    EXISTS (SELECT 1 FROM res_ent_okey k WHERE k.obs_ent_id = u.obs_ent_id) AS has_res_ent_okey
FROM _unresolved u
LEFT JOIN obs_ent     o ON o.obs_ent_id = u.obs_ent_id
LEFT JOIN dsrc_record r ON r.dsrc_id = o.dsrc_id AND r.ent_src_key = o.ent_src_key
ORDER BY o.last_touch_dt;

-- 3. WHEN did they stall? Do the times bunch around the advisory-lock error
--    spikes? Tight clustering => lock-timeout causation; a flat spread across the
--    whole load => a steady background contention rate (what this run showed).
\echo ===== last_touch clustered per 10 minutes (UTC) =====
SELECT to_timestamp(floor(o.last_touch_dt / 600000.0) * 600) AT TIME ZONE 'UTC' AS bucket_utc,
       count(*)
FROM _unresolved u JOIN obs_ent o ON o.obs_ent_id = u.obs_ent_id
GROUP BY 1 ORDER BY 1;

-- 4. Sanity: none should still be queued (the run drained sys_eval_queue to 0).
--    sys_eval_queue keys by (ent_src_key, dsrc_code) -- no obs_ent_id -- so match on
--    ent_src_key (over-matches across data sources, fine as a presence probe).
\echo ===== still queued? (expect 0 rows) =====
SELECT u.obs_ent_id, o.ent_src_key
FROM _unresolved u JOIN obs_ent o ON o.obs_ent_id = u.obs_ent_id
WHERE EXISTS (SELECT 1 FROM sys_eval_queue q WHERE q.ent_src_key = o.ent_src_key);

-- 5. NOTE: these records do NOT auto-recover -- they are not in sys_eval_queue (no
--    pending redo) and were NOT dead-lettered (DLQ=0; the consumer ACK'd them as
--    handled: "kept on source ... self-heals via redo"). So the pipeline has no
--    recovery path and the loss is silent. A manual resubmit of the RECORD_IDs via
--    addRecord would be the only way to remediate / to test transient-vs-permanent.
