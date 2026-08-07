-- =============================================================================
-- progress-live.sql  —  INSTANT progress monitor to run repeatedly DURING a load.
--
-- Replaces count(*)-based progress.sql on large / heavily-loaded DBs. Returns in
-- milliseconds because it reads ONLY the system catalogs / cumulative stats
-- views — it never scans a user table, never holds an MVCC snapshot open, and
-- never pins the vacuum horizon. Safe to loop every 30-60s alongside the
-- IO-metrics harness: it adds ZERO to the monitored tables' heap/idx/seq_scan
-- counters and only a few dozen catalog blks_hit to the DB-wide
-- pg_stat_database scalars per poll.
-- (Pause this loop for the few seconds around 10-baseline.sql / 20-final.sql so
--  no poll straddles a snapshot boundary.)
--
-- HEADLINE PROGRESS IS EXACT for dsrc_record: driven from n_tup_ins, the
-- cumulative committed-insert counter, which for an insert-only, never-TRUNCATEd
-- table EQUALS the true row count and is refreshed continuously by the stats
-- collector (NOT gated on autoanalyze). reltuples/n_live_tup are shown only as a
-- secondary shape indicator for the churn tables and must NEVER drive the % or a
-- plateau decision (they lag analyze — can under-read ~9% and lag 30+ min).
-- =============================================================================
\set ON_ERROR_STOP on
\timing on

-- --- (1) Per-table depth + churn health (one fast catalog read) ---------------
SELECT
    now()                                              AS at,
    s.schemaname,
    s.relname,
    s.n_tup_ins                                        AS cum_ins,        -- exact for insert-only
    s.n_tup_del                                        AS cum_del,
    (s.n_tup_ins - s.n_tup_del)                        AS est_net_depth,  -- ~live rows on churn queue
    c.reltuples::bigint                                AS est_rows_reltuples,  -- planner estimate; shape only
    s.n_live_tup                                       AS est_live_tup,   -- analyze-gated; shape only
    s.n_dead_tup                                       AS est_dead_tup,
    s.n_mod_since_analyze                              AS mods_since_analyze,
    s.last_autovacuum,
    s.autovacuum_count,
    s.last_analyze,
    s.last_autoanalyze
FROM pg_stat_user_tables s
JOIN pg_class c ON c.oid = s.relid
WHERE s.relname IN ('dsrc_record','obs_ent','res_ent','res_ent_okey',
                    'sys_eval_queue','res_relate')
ORDER BY s.relname;

-- --- (2) Progress toward the load target (EXACT for insert-only dsrc_record) ---
-- Driven from n_tup_ins, NOT reltuples. Change the target literal if RecordMax
-- differs from 100,000,000.
SELECT
    now()                                              AS at,
    s.n_tup_ins                                        AS dsrc_record_rows,   -- exact (insert-only)
    100000000                                          AS target,
    round(100.0 * s.n_tup_ins / 100000000, 2)          AS pct_of_target
FROM pg_stat_user_tables s
WHERE s.relname = 'dsrc_record';

-- --- (3) Horizon watchdog: is anything pinning the vacuum horizon? -------------
-- A large xmin_age_xids on a long-running backend means dead tuples on
-- sys_eval_queue cannot be reclaimed. A long count(*) is the classic culprit;
-- this monitor itself holds no snapshot, so it will NOT appear here.
SELECT
    pid,
    state,
    now() - xact_start                                 AS xact_age,
    now() - query_start                                AS query_age,
    age(backend_xmin)                                  AS xmin_age_xids,
    left(regexp_replace(query, '\s+', ' ', 'g'), 60)   AS query
FROM pg_stat_activity
WHERE datname = current_database()
  AND backend_xmin IS NOT NULL
ORDER BY age(backend_xmin) DESC NULLS LAST
LIMIT 5;

-- =============================================================================
-- GATING RULE: move to the end-of-run capture only when dsrc_record.cum_ins is
-- FLAT across two consecutive polls AND ~= the load target — AND the external
-- loader-done signal is in AND sys_eval_queue has truly drained (see the runbook
-- "drain gate" and drain-check.sql). Never gate on a reltuples/n_live_tup
-- plateau (ambiguous).
-- =============================================================================
