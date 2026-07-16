-- =============================================================================
-- drain-check.sql  —  the DRAIN GATE. Run repeatedly (~30-60s apart) once the
-- loader reports done, to decide whether it is safe to run final-capture.sql.
--
-- The AUTHORITATIVE "done" signal is EXTERNAL: the Senzing loader has submitted
-- its last addRecord AND redo/resolution is idle. dsrc_record inserts finishing
-- is ORTHOGONAL to sys_eval_queue draining — resolution is asynchronous and the
-- queue keeps churning after the last insert — so NEVER declare done on the
-- insert count alone. The queries below are CONFIRMATORY, not a substitute for
-- the loader-done signal. Do NOT trust reltuples/n_live_tup for this decision.
--
-- Trigger final-capture.sql only when ALL hold:
--   (a) external loader-done signal is in;
--   (b) query (2) shows ~0 active Senzing client backends (only this monitor);
--   (c) Stage A: cum_ins AND cum_del FLAT across two consecutive polls for BOTH
--       tables, with NO regression (if a counter DECREASES, a failover/TRUNCATE
--       reset the epoch — discard the run per the harness README; restart);
--   (d) Stage B: EXISTS probe returns 'f' on >=3 consecutive polls ~60s apart
--       (a single 'f' can be a transient mid-run dip in a producer/consumer queue).
-- =============================================================================
\set ON_ERROR_STOP on
\timing on

-- --- Stage A: have writers stopped? (flat, non-regressing cumulative counters)-
SELECT
    now()                    AS at,
    relname,
    n_tup_ins                AS cum_ins,
    n_tup_del                AS cum_del,
    (n_tup_ins - n_tup_del)  AS est_net_depth,
    n_live_tup               AS est_live_tup,
    n_dead_tup               AS est_dead_tup
FROM pg_stat_user_tables
WHERE relname IN ('dsrc_record','sys_eval_queue')
ORDER BY relname;

-- --- (2) No active Senzing backend? (only this monitor's own connection) ------
SELECT count(*) AS active_client_backends
FROM pg_stat_activity
WHERE datname = current_database()
  AND state = 'active'
  AND backend_type = 'client backend'
  AND pid <> pg_backend_pid();

-- --- Stage B: TRUE-ZERO confirmation for sys_eval_queue (bounded, never a full
-- scan). Returns t (rows remain) or f (drained). Trust 'f' only after (a)-(c)
-- hold AND across >=3 consecutive polls. Run VACUUM (final-capture Step 0b)
-- before fully trusting 'f' so a bloated dead-tuple heap can't make even LIMIT 1
-- wade through pages under enable_seqscan=0.
SELECT EXISTS (SELECT 1 FROM sys_eval_queue LIMIT 1) AS sys_eval_queue_has_rows;
